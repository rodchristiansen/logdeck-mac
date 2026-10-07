import Foundation

/// manageusers: one directory per day,
/// /Library/Managed Users/logs/YYYY-MM-DD/manageusers.log. The flat
/// manageusers.log and its rolled generations at the root predate that layout
/// and are still listed.
public struct ManageUsersModule: ToolModule {
    public init() {}
    public let id = "manageusers"
    public let name = "ManageUsers"
    public let role = "Users"
    public let icon = "person.2.badge.gearshape"
    public let category = ToolCategory.managementTools

    public let detectionPaths = [
        "/Applications/Utilities/Managed Users Cleanup.app",
        "/usr/local/manageusers/manageusers",
        "/Library/Managed Users/logs"
    ]

    public let logDirectories = [
        LogDirectory(
            id: "manageusers-days",
            label: "Daily Logs",
            paths: ["/Library/Managed Users/logs"],
            sessionLogNames: ["manageusers.log"]
        )
    ]

    public let logSources: [LogSource] = []

    public let supportPaths = [
        SupportPath(
            id: "manageusers-prefs",
            label: "Preferences",
            path: "/Library/Preferences/com.github.manageusers.plist",
            kind: .configuration
        ),
        SupportPath(
            id: "manageusers-app",
            label: "Managed Users Cleanup",
            path: "/Applications/Utilities/Managed Users Cleanup.app",
            kind: .binary
        )
    ]
}
