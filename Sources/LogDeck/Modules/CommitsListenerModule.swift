import Foundation

struct CommitsListenerModule: ToolModule {
    let id = "commits-listener"
    let name = "CommitsListener"
    let icon = "arrow.triangle.merge"
    let category = ToolCategory.other

    let detectionPaths = [
        "~/Library/Logs/CommitsListener"
    ]

    var isInstalled: Bool {
        let expanded = ("~/Library/Logs/CommitsListener" as NSString).expandingTildeInPath
        return FileManager.default.fileExists(atPath: expanded)
    }

    let logSources = [
        LogSource(
            id: "commits-listener-logs",
            label: "Listener Logs",
            path: "~/Library/Logs/CommitsListener",
            rotationPattern: ".*\\.log$"
        ),
        LogSource(
            id: "azcopy-logs",
            label: "azcopy Logs",
            path: "~/.azcopy",
            rotationPattern: ".*\\.log$"
        )
    ]

    let supportPaths: [SupportPath] = []
}
