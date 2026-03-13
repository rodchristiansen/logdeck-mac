import Foundation

public struct CommitsListenerModule: ToolModule {
    public init() {}
    public let id = "commits-listener"
    public let name = "CommitsListener"
    public let icon = "arrow.triangle.merge"
    public let category = ToolCategory.other

    public let detectionPaths = [
        "~/Library/Logs/CommitsListener"
    ]

    public var isInstalled: Bool {
        let expanded = ("~/Library/Logs/CommitsListener" as NSString).expandingTildeInPath
        return FileManager.default.fileExists(atPath: expanded)
    }

    public let logSources = [
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

    public let supportPaths: [SupportPath] = []
}
