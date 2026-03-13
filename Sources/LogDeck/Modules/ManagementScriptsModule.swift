import Foundation

struct ManagementScriptsModule: ToolModule {
    let id = "management-scripts"
    let name = "Management Scripts"
    let icon = "applescript"
    let category = ToolCategory.scripting

    let detectionPaths = [
        "/Library/Management/Scripts",
        "/Library/Management/Logs"
    ]

    let logSources = [
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

    let supportPaths = [
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
