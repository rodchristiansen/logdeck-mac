import Foundation

/// BootstrapMate: one session directory per run,
/// /Library/Managed Bootstrap/logs/YYYY-MM-DD/HHMMSS/bootstrap.log. A run that
/// could not create its session directory writes YYYY-MM-DD-HHMMSS.log at the root.
public struct BootstrapMateModule: ToolModule {
    public init() {}
    public let id = "bootstrapmate"
    public let name = "BootstrapMate"
    public let role = "Bootstrap"
    public let icon = "arrow.trianglehead.2.counterclockwise"
    public let category = ToolCategory.managementTools

    public let detectionPaths = [
        "/Applications/Utilities/Managed Bootstrap Install.app",
        "/usr/local/bootstrapmate/managedbootstrapinstall",
        "/Library/Managed Bootstrap/logs"
    ]

    public let logDirectories = [
        LogDirectory(
            id: "bootstrapmate-sessions",
            label: "Run Sessions",
            paths: ["/Library/Managed Bootstrap/logs"],
            sessionLogNames: ["bootstrap.log"]
        )
    ]

    public let logSources = [
        LogSource(
            id: "bootstrapmate-postinstall",
            label: "Package postinstall",
            path: "/tmp/bootstrapmate-postinstall.log"
        )
    ]

    public let supportPaths = [
        SupportPath(
            id: "bootstrapmate-prefs",
            label: "Preferences",
            path: "/Library/Preferences/com.github.bootstrapmate.plist",
            kind: .configuration
        ),
        SupportPath(
            id: "bootstrapmate-cache",
            label: "Cache",
            path: "/Library/Managed Bootstrap/cache",
            kind: .cache
        ),
        SupportPath(
            id: "bootstrapmate-app",
            label: "Managed Bootstrap Install",
            path: "/Applications/Utilities/Managed Bootstrap Install.app",
            kind: .binary
        )
    ]
}
