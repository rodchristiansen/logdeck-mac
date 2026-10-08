import Foundation

/// Outset: one session directory per run,
/// /Library/Managed State/logs/YYYY-MM-DD/HHMMSS/outset.log. The flat outset.log
/// and its rotations at the root predate that layout and are still listed.
/// Runs as the user (login-every, login-once) write the same layout under
/// ~/Library/Logs/Managed State, which ModuleLogs lists as "This user". Older
/// builds wrote ~/Library/Logs/outset.log when the shared folder was closed.
public struct OutsetModule: ToolModule {
    public init() {}
    public let id = "outset"
    public let name = "Outset"
    public let role = "State"
    public let icon = "terminal"
    public let category = ToolCategory.managementTools

    public let detectionPaths = [
        "/Applications/Utilities/Managed State Keeper.app",
        "/usr/local/outset/outset",
        "/Library/Managed State/logs"
    ]

    public let logDirectories = [
        LogDirectory(
            id: "outset-sessions",
            label: "Run Sessions",
            paths: ["/Library/Managed State/logs"],
            sessionLogNames: ["outset.log"]
        )
    ]

    public let logSources = [
        LogSource(
            id: "outset-user",
            label: "Your log (fallback)",
            path: "~/Library/Logs/outset.log"
        )
    ]

    public let supportPaths = [
        SupportPath(
            id: "outset-prefs",
            label: "Preferences",
            path: "/Library/Preferences/io.macadmins.Outset.plist",
            kind: .configuration
        ),
        SupportPath(
            id: "outset-scripts",
            label: "Script Folders",
            path: "/usr/local/outset",
            kind: .scripts
        ),
        SupportPath(
            id: "outset-app",
            label: "Managed State Keeper",
            path: "/Applications/Utilities/Managed State Keeper.app",
            kind: .binary
        )
    ]
}
