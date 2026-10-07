import Foundation
import Core

@main
struct LogDeckCLI {
    static func main() async {
        let args = CommandLine.arguments.dropFirst()

        guard let toolName = args.first else {
            printToolList()
            return
        }

        if toolName == "--help" || toolName == "-h" {
            printUsage()
            return
        }

        guard let module = ModuleRegistry.find(toolName) else {
            printError("Unknown tool: \(toolName)")
            printToolList()
            Darwin.exit(1)
        }

        let remainingArgs = Array(args.dropFirst())
        let logs = ModuleLogs(module: module)

        if remainingArgs.contains("--list") || remainingArgs.contains("-l") {
            printLogSources(module, logs)
            return
        }

        guard let source = logs.newest else {
            printNoLogs(module, logs)
            Darwin.exit(1)
        }

        if remainingArgs.contains("--follow") || remainingArgs.contains("-f") {
            await tail(source)
        } else {
            await show(source, lines: 200)
        }
    }
}

// MARK: - Commands

private func printUsage() {
    print("""
    logdeck - local logs of the Mac management tools

    USAGE:
      logdeck                  List the tools and how many logs each has
      logdeck <tool>           Show the end of the tool's newest log
      logdeck <tool> -f        Follow the tool's newest log
      logdeck <tool> -l        List every log the tool has, newest first

    TOOLS (by id or role):
    \(ModuleRegistry.allModules.map { "  \($0.id.padding(toLength: 20, withPad: " ", startingAt: 0))\($0.role)" }.joined(separator: "\n"))
    """)
}

private func printToolList() {
    let modules = ModuleRegistry.allModules
    print("logdeck - local logs of the Mac management tools\n")

    let width = (modules.map(\.id.count).max() ?? 0) + 2
    for module in modules {
        let logs = ModuleLogs(module: module)
        let count = logs.folders.reduce(0) { $0 + $1.sessions.count } + logs.existingFiles.count
        let status = module.isInstalled ? "\u{001B}[32m●\u{001B}[0m" : "\u{001B}[90m○\u{001B}[0m"
        let id = module.id.padding(toLength: width, withPad: " ", startingAt: 0)
        let role = module.role.padding(toLength: 15, withPad: " ", startingAt: 0)
        let summary = !logs.unreadableFolders.isEmpty ? "needs root" : (count == 0 ? "no logs" : "\(count) logs")
        print("  \(status) \(id)\(role)\(summary)")
    }
    print("\nRun 'logdeck <tool>' to view logs, or 'logdeck --help' for more options.")
}

private func printLogSources(_ module: any ToolModule, _ logs: ModuleLogs) {
    print("\(module.name) (\(module.role))\n")
    for folder in logs.folders {
        print("\u{001B}[1m\(folder.directory.label)\u{001B}[0m  \u{001B}[90m\(folder.directory.resolvedPath)\u{001B}[0m")
        switch folder.status {
        case .missing: print("  folder not found")
        case .unreadable: print("  \u{001B}[33mneeds root to read\u{001B}[0m")
        case .available where folder.sessions.isEmpty: print("  no logs yet")
        case .available:
            for session in folder.sessions {
                let date = session.displayDate.padding(toLength: 24, withPad: " ", startingAt: 0)
                print("  \(date)\(session.displaySize.padding(toLength: 10, withPad: " ", startingAt: 0))\(session.path)")
            }
        }
        print()
    }
    for source in logs.files {
        let status = source.exists ? "\u{001B}[32m✓\u{001B}[0m" : "\u{001B}[90m✗\u{001B}[0m"
        print("  \(status) \(source.label)  \u{001B}[90m\(source.resolvedPath)\u{001B}[0m")
    }
}

private func printNoLogs(_ module: any ToolModule, _ logs: ModuleLogs) {
    if let unreadable = logs.unreadableFolders.first {
        printError("\(unreadable.resolvedPath) needs root to read. Try: sudo logdeck \(module.id)")
    } else if module.isInstalled {
        printError("\(module.name) has not written any logs yet.")
    } else {
        printError("\(module.name) is not installed and has no logs on this Mac.")
    }
}

private func show(_ source: LogSource, lines: Int) async {
    printHeader(source.label, path: source.resolvedPath)
    do {
        for entry in try await LogReader().readLog(from: source).suffix(lines) {
            printLogLine(entry)
        }
    } catch {
        printError(error.localizedDescription)
    }
}

private func tail(_ source: LogSource) async {
    await show(source, lines: 50)
    print("\u{001B}[90mFollowing; press Ctrl+C to stop\u{001B}[0m")

    let reader = LogReader()
    let size = (try? FileManager.default.attributesOfItem(atPath: source.resolvedPath))?[.size] as? NSNumber
    var position = size?.uint64Value ?? 0
    while true {
        try? await Task.sleep(for: .seconds(1))
        do {
            let (entries, newOffset) = try await reader.readTail(from: source, offset: position)
            entries.forEach(printLogLine)
            position = newOffset
        } catch {
            break
        }
    }
}

// MARK: - Output Helpers

private func printHeader(_ title: String, path: String) {
    print("\u{001B}[1;36m━━━ \(title) ━━━\u{001B}[0m")
    print("\u{001B}[90m\(path)\u{001B}[0m\n")
}

private func printLogLine(_ entry: LogEntry) {
    let line = entry.line
    guard !line.isEmpty else { return }
    switch entry.level {
    case .error: print("\u{001B}[31m\(line)\u{001B}[0m")
    case .warning: print("\u{001B}[33m\(line)\u{001B}[0m")
    case .success: print("\u{001B}[32m\(line)\u{001B}[0m")
    case .header: print("\u{001B}[36m\(line)\u{001B}[0m")
    case .debug: print("\u{001B}[90m\(line)\u{001B}[0m")
    case .info: print(line)
    }
}

private func printError(_ message: String) {
    FileHandle.standardError.write(Data("\u{001B}[31mError: \(message)\u{001B}[0m\n".utf8))
}
