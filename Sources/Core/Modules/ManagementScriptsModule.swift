import Foundation

/// Locally deployed management scripts that log to /Library/Management/Logs.
public struct ManagementScriptsModule: ToolModule {
    public init() {}
    public let id = "management-scripts"
    public let name = "Management Scripts"
    public let role = "Scripts"
    public let icon = "applescript"
    public let category = ToolCategory.scripting

    public let detectionPaths = [
        "/Library/Management/Scripts",
        "/Library/Management/Logs"
    ]

    public let logDirectories = [
        LogDirectory(
            id: "mgmt-logs",
            label: "Logs",
            paths: ["/Library/Management/Logs"],
            flatFilePattern: #"\.(log|err)(\.\d+)?$"#
        )
    ]

    public let logSources: [LogSource] = []

    public let supportPaths = [
        SupportPath(
            id: "mgmt-scripts",
            label: "Scripts",
            path: "/Library/Management/Scripts",
            kind: .scripts
        ),
        SupportPath(
            id: "mgmt-cache",
            label: "Cache",
            path: "/Library/Management/Cache",
            kind: .cache
        )
    ]
}
