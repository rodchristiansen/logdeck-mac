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

        if remainingArgs.contains("--list") || remainingArgs.contains("-l") {
            printLogSources(module)
            return
        }

        let shouldFollow = remainingArgs.contains("--follow") || remainingArgs.contains("-f")

        if shouldFollow {
            await tailLogs(module)
        } else {
            await showLogs(module)
        }
    }
}

// MARK: - Commands

private func printUsage() {
    let usage = """
    logdeck - Mac admin log viewer

    USAGE:
      logdeck                  List detected tools
      logdeck <tool>           Show logs for a tool
      logdeck <tool> -f        Follow/tail logs
      logdeck <tool> -l        List log file paths

    TOOLS:
    \(ModuleRegistry.allModules.map { "  \($0.id)" }.joined(separator: "\n"))
    """
    print(usage)
}

private func printToolList() {
    let detector = ToolDetector()
    let modules = ModuleRegistry.allModules

    print("logdeck - Mac admin log viewer\n")
    print("Available tools:\n")

    let maxNameLen = modules.map(\.id.count).max() ?? 0

    for module in modules {
        let result = detector.detect(module)
        let status = result.isInstalled ? "\u{001B}[32m●\u{001B}[0m" : "\u{001B}[90m○\u{001B}[0m"
        let name = module.id.padding(toLength: maxNameLen + 2, withPad: " ", startingAt: 0)
        let label = result.isInstalled ? module.name : "\u{001B}[90m\(module.name)\u{001B}[0m"
        let logCount = module.logSources.count
        let existing = module.logSources.filter(\.exists).count
        let files = result.isInstalled ? "  (\(existing)/\(logCount) logs found)" : ""
        print("  \(status) \(name)\(label)\(files)")
    }

    print("\nRun 'logdeck <tool>' to view logs, or 'logdeck --help' for more options.")
}

private func printLogSources(_ module: any ToolModule) {
    print("\(module.name) log sources:\n")
    for source in module.logSources {
        let exists = source.exists
        let status = exists ? "\u{001B}[32m✓\u{001B}[0m" : "\u{001B}[31m✗\u{001B}[0m"
        let priv = source.requiresPrivilege ? " \u{001B}[33m(root)\u{001B}[0m" : ""
        print("  \(status) \(source.label)\(priv)")
        print("    \(source.resolvedPath)")
        if exists, let size = source.fileSize {
            print("    \(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))")
        }
        print()
    }
}

private func showLogs(_ module: any ToolModule) async {
    let reader = LogReader()
    let readableSources = module.logSources.filter { $0.exists && !$0.requiresPrivilege }

    if readableSources.isEmpty {
        let privileged = module.logSources.filter { $0.requiresPrivilege && $0.exists }
        if !privileged.isEmpty {
            printError("All available logs require root access. Try: sudo logdeck \(module.id)")
        } else {
            printError("No log files found for \(module.name).")
        }
        return
    }

    for source in readableSources {
        printHeader(source.label, path: source.resolvedPath)
        do {
            let entries = try await reader.readLog(from: source)
            for entry in entries.suffix(200) {
                printLogLine(entry)
            }
        } catch {
            printError("  Error: \(error.localizedDescription)")
        }
        print()
    }
}

private func tailLogs(_ module: any ToolModule) async {
    let sources = module.logSources.filter { $0.exists && !$0.requiresPrivilege }

    guard let source = sources.first else {
        printError("No readable log files found for \(module.name).")
        return
    }

    printHeader("Tailing \(source.label)", path: source.resolvedPath)
    print("\u{001B}[90mPress Ctrl+C to stop\u{001B}[0m\n")

    let reader = LogReader()

    // Show last 50 lines first
    do {
        let entries = try await reader.readLog(from: source)
        for entry in entries.suffix(50) {
            printLogLine(entry)
        }
    } catch {
        printError("Error: \(error.localizedDescription)")
        return
    }

    // Poll for new content
    var offset: UInt64 = 0
    if let attrs = try? FileManager.default.attributesOfItem(atPath: source.resolvedPath),
       let size = attrs[.size] as? UInt64 {
        offset = size
    }

    while true {
        try? await Task.sleep(for: .seconds(1))
        do {
            let (entries, newOffset) = try await reader.readTail(from: source, offset: offset)
            for entry in entries {
                printLogLine(entry)
            }
            offset = newOffset
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

    switch entry.severity {
    case .error:
        print("\u{001B}[31m\(line)\u{001B}[0m")
    case .warning:
        print("\u{001B}[33m\(line)\u{001B}[0m")
    case .debug:
        print("\u{001B}[90m\(line)\u{001B}[0m")
    case .info:
        print(line)
    }
}

private func printError(_ message: String) {
    FileHandle.standardError.write(Data("\u{001B}[31mError: \(message)\u{001B}[0m\n".utf8))
}
