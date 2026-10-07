import Foundation

/// The small utilities (dockutil and others) share one folder, one directory
/// per day: /Library/Managed Utilities/logs/YYYY-MM-DD/<tool>.log.
public struct UtilitiesModule: ToolModule {
    public init() {}
    public let id = "utilities"
    public let name = "Utilities"
    public let role = "dockutil and others"
    public let icon = "wrench.and.screwdriver"
    public let category = ToolCategory.managementTools

    public let detectionPaths = [
        "/usr/local/bin/dockutil",
        "/Library/Managed Utilities/logs"
    ]

    public let logDirectories = [
        LogDirectory(
            id: "utilities-days",
            label: "Daily Logs",
            paths: ["/Library/Managed Utilities/logs"]
        )
    ]

    public let logSources: [LogSource] = []
    public let supportPaths: [SupportPath] = []
}
