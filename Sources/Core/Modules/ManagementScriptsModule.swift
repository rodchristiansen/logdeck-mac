import Foundation

public struct ManagementScriptsModule: ToolModule {
    public init() {}
    public let id = "management-scripts"
    public let name = "Management Scripts"
    public let icon = "applescript"
    public let category = ToolCategory.scripting

    public let detectionPaths = [
        "/Library/Management/Scripts",
        "/Library/Management/Logs"
    ]

    public let logSources = [
        LogSource(
            id: "mgmt-nightly-bootstrap",
            label: "NightlyBootstrap.log",
            path: "/Library/Management/Logs/NightlyBootstrap.log"
        ),
        LogSource(
            id: "mgmt-nightly-bootstrap-err",
            label: "NightlyBootstrap.err",
            path: "/Library/Management/Logs/NightlyBootstrap.err"
        ),
        LogSource(
            id: "mgmt-manage-users",
            label: "ManageUsers.log",
            path: "/Library/Management/Logs/ManageUsers.log"
        )
    ]

    public let supportPaths = [
        SupportPath(
            id: "mgmt-scripts",
            label: "Management Scripts",
            path: "/Library/Management/Scripts",
            kind: .scripts
        ),
        SupportPath(
            id: "mgmt-cache",
            label: "Management Cache",
            path: "/Library/Management/Cache",
            kind: .cache
        ),
        SupportPath(
            id: "mgmt-remediation",
            label: "Remediation Scripts",
            path: "/Library/Management/Remediation",
            kind: .scripts
        )
    ]
}
