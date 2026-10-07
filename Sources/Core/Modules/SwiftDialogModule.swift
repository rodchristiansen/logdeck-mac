import Foundation

/// swiftDialog: one log per day, shared by every user and root,
/// /Library/Managed Notifications/logs/YYYY-MM-DD/dialog.log, rolled at 5 MB into
/// dialog.log.1 … dialog.log.5 beside it. When that folder is unavailable dialog
/// writes ~/Library/Logs/dialog.log instead.
public struct SwiftDialogModule: ToolModule {
    public init() {}
    public let id = "swiftdialog"
    public let name = "swiftDialog"
    public let role = "Notifications"
    public let icon = "bubble.left.and.text.bubble.right"
    public let category = ToolCategory.managementTools

    public let detectionPaths = [
        "/Applications/Utilities/Managed Notifications Dialog.app",
        "/usr/local/bin/dialog",
        "/Library/Application Support/Dialog/Dialog.app",
        "/Library/Managed Notifications/logs"
    ]

    public let logDirectories = [
        LogDirectory(
            id: "swiftdialog-days",
            label: "Daily Logs",
            paths: ["/Library/Managed Notifications/logs"],
            sessionLogNames: ["dialog.log"]
        )
    ]

    public let logSources = [
        LogSource(
            id: "swiftdialog-user",
            label: "Your log (fallback)",
            path: "~/Library/Logs/dialog.log"
        )
    ]

    public let supportPaths = [
        SupportPath(
            id: "swiftdialog-app",
            label: "Dialog.app",
            path: "/Library/Application Support/Dialog/Dialog.app",
            kind: .binary
        ),
        SupportPath(
            id: "swiftdialog-gui",
            label: "Managed Notifications Dialog",
            path: "/Applications/Utilities/Managed Notifications Dialog.app",
            kind: .binary
        )
    ]
}
