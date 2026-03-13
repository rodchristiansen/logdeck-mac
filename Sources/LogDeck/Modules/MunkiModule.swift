import Foundation

struct MunkiModule: ToolModule {
    let id = "munki"
    let name = "Munki"
    let icon = "shippingbox"
    let category = ToolCategory.packageManagement

    let detectionPaths = [
        "/usr/local/munki/managedsoftwareupdate",
        "/Library/Managed Installs"
    ]

    let logSources = [
        LogSource(
            id: "munki-msu-log",
            label: "ManagedSoftwareUpdate.log",
            path: "/Library/Managed Installs/Logs/ManagedSoftwareUpdate.log"
        ),
        LogSource(
            id: "munki-errors",
            label: "Errors",
            path: "/Library/Managed Installs/Logs/errors.log"
        ),
        LogSource(
            id: "munki-warnings",
            label: "Warnings",
            path: "/Library/Managed Installs/Logs/warnings.log"
        ),
        LogSource(
            id: "munki-install-log",
            label: "Install Log (system)",
            path: "/var/log/install.log",
            requiresPrivilege: true
        )
    ]

    let supportPaths = [
        SupportPath(
            id: "munki-prefs",
            label: "Munki Preferences",
            path: "/Library/Preferences/ManagedInstalls.plist",
            kind: .configuration
        ),
        SupportPath(
            id: "munki-cache",
            label: "Package Cache",
            path: "/Library/Managed Installs/Cache",
            kind: .cache
        ),
        SupportPath(
            id: "munki-catalogs",
            label: "Catalogs",
            path: "/Library/Managed Installs/catalogs",
            kind: .data
        ),
        SupportPath(
            id: "munki-manifests",
            label: "Manifests",
            path: "/Library/Managed Installs/manifests",
            kind: .data
        ),
        SupportPath(
            id: "munki-binaries",
            label: "Munki Binaries",
            path: "/usr/local/munki",
            kind: .binary
        )
    ]
}
