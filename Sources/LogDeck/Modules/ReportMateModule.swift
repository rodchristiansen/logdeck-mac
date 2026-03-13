import Foundation

struct ReportMateModule: ToolModule {
    let id = "reportmate"
    let name = "ReportMate"
    let icon = "chart.bar.doc.horizontal"
    let category = ToolCategory.reporting

    let detectionPaths = [
        "/usr/local/reportmate/ReportMate.app",
        "/usr/local/munkireport/munkireport-runner"
    ]

    let logSources = [
        LogSource(
            id: "reportmate-unenroll",
            label: "Unenroll Log",
            path: "/var/log/munkireport_unenroll.log",
            requiresPrivilege: true
        )
    ]

    let supportPaths = [
        SupportPath(
            id: "reportmate-prefs",
            label: "MunkiReport Preferences",
            path: "/Library/Preferences/MunkiReport.plist",
            kind: .configuration
        ),
        SupportPath(
            id: "reportmate-cache",
            label: "Script Cache",
            path: "/usr/local/munkireport/scripts/cache",
            kind: .cache
        ),
        SupportPath(
            id: "reportmate-scripts",
            label: "MunkiReport Scripts",
            path: "/usr/local/munkireport/scripts",
            kind: .scripts
        ),
        SupportPath(
            id: "reportmate-runner",
            label: "ReportMate Runner",
            path: "/usr/local/reportmate/ReportMate.app",
            kind: .binary
        )
    ]
}
