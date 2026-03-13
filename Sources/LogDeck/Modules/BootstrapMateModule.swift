import Foundation

struct BootstrapMateModule: ToolModule {
    let id = "bootstrapmate"
    let name = "BootstrapMate"
    let icon = "arrow.trianglehead.2.counterclockwise"
    let category = ToolCategory.bootstrap

    let detectionPaths = [
        "/Applications/Utilities/BootstrapMate.app",
        "/Library/Managed Bootstrap",
        "/usr/local/bootstrapmate"
    ]

    let logSources = [
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

    let supportPaths = [
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
