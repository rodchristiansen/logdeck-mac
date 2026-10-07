import Foundation

/// ReportMate: flat files in /Library/Managed Reports/logs. reportmate.log is
/// the current log, rolled daily to reportmate-YYYY-MM-DD.log, beside each
/// launchd job's output. When that folder is unavailable the client writes
/// ~/Library/Logs/ReportMate/reportmate.log instead.
public struct ReportMateModule: ToolModule {
    public init() {}
    public let id = "reportmate"
    public let name = "ReportMate"
    public let role = "Reports"
    public let icon = "chart.bar.doc.horizontal"
    public let category = ToolCategory.managementTools

    public let detectionPaths = [
        "/Applications/Utilities/Managed Reports Runner.app",
        "/usr/local/reportmate/managedreportsrunner",
        "/Library/Managed Reports/logs"
    ]

    public let logDirectories = [
        LogDirectory(
            id: "reportmate-logs",
            label: "Logs",
            paths: ["/Library/Managed Reports/logs"],
            pinnedName: "reportmate.log"
        )
    ]

    public let logSources = [
        LogSource(
            id: "reportmate-user",
            label: "Your log (fallback)",
            path: "~/Library/Logs/ReportMate/reportmate.log"
        )
    ]

    public let supportPaths = [
        SupportPath(
            id: "reportmate-prefs",
            label: "Preferences",
            path: "/Library/Preferences/com.github.reportmate.plist",
            kind: .configuration
        ),
        SupportPath(
            id: "reportmate-cache",
            label: "Cache",
            path: "/Library/Managed Reports/cache",
            kind: .cache
        ),
        SupportPath(
            id: "reportmate-app",
            label: "Managed Reports Runner",
            path: "/Applications/Utilities/Managed Reports Runner.app",
            kind: .binary
        )
    ]
}
