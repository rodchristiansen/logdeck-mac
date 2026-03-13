import Foundation

public struct IntuneModule: ToolModule {
    public init() {}
    public let id = "intune"
    public let name = "Intune"
    public let icon = "shield.checkered"
    public let category = ToolCategory.mdm

    public let detectionPaths = [
        "/Library/Logs/Microsoft/Intune",
        "/Library/Intune"
    ]

    public let logSources = [
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

    public let supportPaths = [
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
