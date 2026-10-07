import Foundation

/// Munki: the flat logs in /Library/Managed Installs/logs (Logs/ before the
/// session layout renamed it), and one session directory per run,
/// logs/YYYY-MM-DD/HHMM/, holding run.log and install.log.
public struct MunkiModule: ToolModule {
    public init() {}
    public let id = "munki"
    public let name = "Munki"
    public let role = "Installs"
    public let icon = "shippingbox"
    public let category = ToolCategory.managementTools

    public let detectionPaths = [
        "/usr/local/munki/managedsoftwareupdate",
        "/Applications/Managed Software Center.app",
        "/Library/Managed Installs"
    ]

    public let logDirectories = [
        LogDirectory(
            id: "munki-sessions",
            label: "Run Sessions",
            paths: ["/Library/Managed Installs/logs", "/Library/Managed Installs/Logs"],
            sessionLogNames: ["run.log", "install.log"],
            includesFlatFiles: false
        )
    ]

    public let logSources = [
        Self.log("munki-msu-log", "ManagedSoftwareUpdate.log"),
        Self.log("munki-install", "Install.log"),
        Self.log("munki-errors", "errors.log"),
        Self.log("munki-warnings", "warnings.log"),
        Self.log("munki-installhelper", "installhelper.log"),
        LogSource(
            id: "munki-system-install-log",
            label: "install.log (system)",
            path: "/var/log/install.log"
        )
    ]

    private static func log(_ id: String, _ name: String) -> LogSource {
        LogSource(
            id: id,
            label: name,
            path: "/Library/Managed Installs/logs/\(name)",
            fallbackPaths: ["/Library/Managed Installs/Logs/\(name)"]
        )
    }

    public let supportPaths = [
        SupportPath(
            id: "munki-prefs",
            label: "Preferences",
            path: "/Library/Preferences/ManagedInstalls.plist",
            kind: .configuration
        ),
        SupportPath(
            id: "munki-reports",
            label: "Reports",
            path: "/Library/Managed Installs/reports",
            kind: .data
        ),
        SupportPath(
            id: "munki-cache",
            label: "Package Cache",
            path: "/Library/Managed Installs/Cache",
            kind: .cache
        ),
        SupportPath(
            id: "munki-manifests",
            label: "Manifests",
            path: "/Library/Managed Installs/manifests",
            kind: .data
        ),
        SupportPath(
            id: "munki-binaries",
            label: "Munki Tools",
            path: "/usr/local/munki",
            kind: .binary
        )
    ]
}
