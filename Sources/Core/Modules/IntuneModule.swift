import Foundation

/// Microsoft Intune: the management daemon's logs, one file per rotation, in
/// /Library/Logs/Microsoft/Intune, and Company Portal's in the user's library.
public struct IntuneModule: ToolModule {
    public init() {}
    public let id = "intune"
    public let name = "Intune"
    public let role = "MDM agent"
    public let icon = "shield.checkered"
    public let category = ToolCategory.mdm

    public let detectionPaths = [
        "/Library/Intune",
        "/Library/Logs/Microsoft/Intune",
        "/Applications/Company Portal.app"
    ]

    public let logDirectories = [
        LogDirectory(
            id: "intune-daemon",
            label: "Intune Agent",
            paths: ["/Library/Logs/Microsoft/Intune"]
        ),
        LogDirectory(
            id: "intune-company-portal",
            label: "Company Portal",
            paths: ["~/Library/Logs/Company Portal"]
        )
    ]

    public let logSources: [LogSource] = []

    public let supportPaths = [
        SupportPath(
            id: "intune-scripts",
            label: "Intune Scripts",
            path: "/Library/Application Support/Microsoft/IntuneScripts",
            kind: .scripts
        )
    ]
}
