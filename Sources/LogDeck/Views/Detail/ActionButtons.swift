import SwiftUI
import AppKit

struct ActionButtons: View {
    let source: LogSource

    var body: some View {
        HStack(spacing: 4) {
            Button {
                revealInFinder()
            } label: {
                Image(systemName: "folder")
            }
            .help("Reveal in Finder")
            .disabled(!source.exists)

            Button {
                copyPath()
            } label: {
                Image(systemName: "doc.on.doc")
            }
            .help("Copy Path")

            Button {
                openInConsole()
            } label: {
                Image(systemName: "apple.terminal")
            }
            .help("Open in Console.app")

            Button {
                openInTerminal()
            } label: {
                Image(systemName: "terminal")
            }
            .help("Tail in Terminal")
            .disabled(!source.exists)
        }
        .buttonStyle(.borderless)
        .controlSize(.small)
    }

    private func revealInFinder() {
        NSWorkspace.shared.selectFile(source.resolvedPath, inFileViewerRootedAtPath: "")
    }

    private func copyPath() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(source.resolvedPath, forType: .string)
    }

    private func openInConsole() {
        let consoleURL = URL(fileURLWithPath: "/System/Applications/Utilities/Console.app")
        NSWorkspace.shared.open(consoleURL)
    }

    private func openInTerminal() {
        let script = """
        tell application "Terminal"
            activate
            do script "tail -f '\(source.resolvedPath)'"
        end tell
        """
        guard let appleScript = NSAppleScript(source: script) else { return }
        var error: NSDictionary?
        appleScript.executeAndReturnError(&error)
    }
}
