import Foundation

/// Crypt: flat files in /Library/Managed Encryption/logs. crypt.log is the
/// current log, which checkin and the login plugin both append to; checkin rolls
/// it daily to crypt-YYYY-MM-DD.log, beside the launchd job's output.
public struct CryptModule: ToolModule {
    public init() {}
    public let id = "crypt"
    public let name = "Crypt"
    public let role = "Encryption"
    public let icon = "lock.shield"
    public let category = ToolCategory.managementTools

    public let detectionPaths = [
        "/Applications/Utilities/Managed Encryption Escrow.app",
        "/Library/Crypt/checkin",
        "/Library/Managed Encryption/logs"
    ]

    public let logDirectories = [
        LogDirectory(
            id: "crypt-logs",
            label: "Logs",
            paths: ["/Library/Managed Encryption/logs"],
            flatFilePattern: #"\.log$"#,
            pinnedName: "crypt.log"
        )
    ]

    public let logSources: [LogSource] = []

    public let supportPaths = [
        SupportPath(
            id: "crypt-prefs",
            label: "Preferences",
            path: "/Library/Preferences/com.grahamgilbert.crypt.plist",
            kind: .configuration
        ),
        SupportPath(
            id: "crypt-binary",
            label: "checkin",
            path: "/Library/Crypt/checkin",
            kind: .binary
        ),
        SupportPath(
            id: "crypt-app",
            label: "Managed Encryption Escrow",
            path: "/Applications/Utilities/Managed Encryption Escrow.app",
            kind: .binary
        )
    ]
}
