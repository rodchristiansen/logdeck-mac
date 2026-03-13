import Foundation

public struct CryptModule: ToolModule {
    public init() {}
    public let id = "crypt"
    public let name = "Crypt"
    public let icon = "lock.shield"
    public let category = ToolCategory.security

    public let detectionPaths = [
        "/Library/Crypt",
        "/usr/local/crypt"
    ]

    public let logSources = [
        LogSource(
            id: "crypt-log",
            label: "Crypt Log",
            path: "/var/log/crypt.log",
            requiresPrivilege: true
        )
    ]

    public let supportPaths = [
        SupportPath(
            id: "crypt-prefs",
            label: "Crypt Preferences",
            path: "/Library/Preferences/com.grahamgilbert.crypt.plist",
            kind: .configuration
        )
    ]
}
