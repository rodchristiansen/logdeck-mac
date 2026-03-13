import Foundation

struct CryptModule: ToolModule {
    let id = "crypt"
    let name = "Crypt"
    let icon = "lock.shield"
    let category = ToolCategory.security

    let detectionPaths = [
        "/Library/Crypt",
        "/usr/local/crypt"
    ]

    let logSources = [
        LogSource(
            id: "crypt-log",
            label: "Crypt Log",
            path: "/var/log/crypt.log",
            requiresPrivilege: true
        )
    ]

    let supportPaths = [
        SupportPath(
            id: "crypt-prefs",
            label: "Crypt Preferences",
            path: "/Library/Preferences/com.grahamgilbert.crypt.plist",
            kind: .configuration
        )
    ]
}
