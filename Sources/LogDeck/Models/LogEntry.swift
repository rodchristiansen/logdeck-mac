import Foundation

struct LogEntry: Identifiable, Sendable {
    let id: Int
    let line: String
    let severity: LogSeverity

    init(id: Int, line: String) {
        self.id = id
        self.line = line
        self.severity = LogSeverity.detect(in: line)
    }
}

enum LogSeverity: Sendable {
    case error
    case warning
    case info
    case debug

    static func detect(in line: String) -> LogSeverity {
        let lowered = line.lowercased()
        if lowered.contains("error") || lowered.contains("fail") || lowered.contains("critical") {
            return .error
        }
        if lowered.contains("warning") || lowered.contains("warn") {
            return .warning
        }
        if lowered.contains("debug") || lowered.contains("verbose") {
            return .debug
        }
        return .info
    }
}
