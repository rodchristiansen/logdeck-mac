import Foundation

struct IntuneModule: ToolModule {
    let id = "intune"
    let name = "Intune"
    let icon = "shield.checkered"
    let category = ToolCategory.mdm

    let detectionPaths = [
        "/Library/Logs/Microsoft/Intune",
        "/Library/Intune"
    ]

    let logSources = [
        LogSource(
            id: "intune-ime-daemon",
            label: "IME Daemon Logs",
            path: "/Library/Logs/Microsoft/Intune",
            requiresPrivilege: true,
            rotationPattern: "IntuneMDMDaemon.*\\.log$"
        ),
        LogSource(
            id: "intune-company-portal",
            label: "Company Portal Logs",
            path: "/Library/Logs/Microsoft/Intune",
            requiresPrivilege: true,
            rotationPattern: "CompanyPortal.*\\.log$"
        ),
        LogSource(
            id: "intune-agent",
            label: "Intune Agent Logs",
            path: "/Library/Logs/Microsoft/Intune",
            requiresPrivilege: true,
            rotationPattern: "IntuneAgent.*\\.log$"
        )
    ]

    let supportPaths = [
        SupportPath(
            id: "intune-scripts",
            label: "Intune Scripts",
            path: "/Library/Application Support/Microsoft/IntuneScripts",
            kind: .scripts
        ),
        SupportPath(
            id: "intune-logs-dir",
            label: "Intune Logs Directory",
            path: "/Library/Logs/Microsoft/Intune",
            kind: .data
        )
    ]
}
