import Foundation

struct InstallApplicationsModule: ToolModule {
    let id = "installapplications"
    let name = "InstallApplications"
    let icon = "arrow.down.app"
    let category = ToolCategory.bootstrap

    let detectionPaths = [
        "/var/log/installapplications",
        "/Library/LaunchDaemons/com.erikng.installapplications.plist"
    ]

    let logSources = [
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

    let supportPaths: [SupportPath] = []
}
