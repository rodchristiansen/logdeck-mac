import Foundation

public struct InstallApplicationsModule: ToolModule {
    public init() {}
    public let id = "installapplications"
    public let name = "InstallApplications"
    public let icon = "arrow.down.app"
    public let category = ToolCategory.bootstrap

    public let detectionPaths = [
        "/var/log/installapplications",
        "/Library/LaunchDaemons/com.erikng.installapplications.plist"
    ]

    public let logSources = [
        LogSource(
            id: "installapps-daemon",
            label: "Daemon Log",
            path: "/var/log/installapplications/installapplications.log",
            requiresPrivilege: true
        ),
        LogSource(
            id: "installapps-user",
            label: "User Log",
            path: "/var/log/installapplications/installapplications.user.log",
            requiresPrivilege: true
        )
    ]

    public let supportPaths: [SupportPath] = []
}
