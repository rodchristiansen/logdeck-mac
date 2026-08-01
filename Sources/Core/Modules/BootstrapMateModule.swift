import Foundation

public struct BootstrapMateModule: ToolModule {
    public init() {}
    public let id = "bootstrapmate"
    public let name = "BootstrapMate"
    public let icon = "arrow.trianglehead.2.counterclockwise"
    public let category = ToolCategory.bootstrap

    public let detectionPaths = [
        "/Applications/Utilities/Managed Bootstrap Install.app",
        "/Applications/Utilities/BootstrapMate.app",
        "/Library/Managed Bootstrap",
        "/usr/local/bootstrapmate"
    ]

    public let logSources = [
        LogSource(
            id: "bootstrapmate-logs",
            label: "Bootstrap Logs",
            path: "/Library/Managed Bootstrap/logs",
            rotationPattern: ".*\\.log$"
        ),
        LogSource(
            id: "bootstrapmate-preflight",
            label: "Preflight Log",
            path: "/var/log/bootstrapmate/preflight.log",
            requiresPrivilege: true
        ),
        LogSource(
            id: "bootstrapmate-install",
            label: "Install Log",
            path: "/var/log/bootstrapmate-install.log",
            requiresPrivilege: true
        ),
        LogSource(
            id: "bootstrapmate-postinstall",
            label: "Postinstall Log",
            path: "/tmp/bootstrapmate-postinstall.log"
        ),
        LogSource(
            id: "bootstrapmate-startup",
            label: "Startup Log",
            path: "/tmp/bootstrapmate-startup.log"
        )
    ]

    public let supportPaths = [
        SupportPath(
            id: "bootstrapmate-prefs",
            label: "BootstrapMate Preferences",
            path: "/Library/Preferences/com.github.bootstrapmate.plist",
            kind: .configuration
        ),
        SupportPath(
            id: "bootstrapmate-cache",
            label: "Bootstrap Cache",
            path: "/Library/Managed Bootstrap/cache",
            kind: .cache
        )
    ]
}
