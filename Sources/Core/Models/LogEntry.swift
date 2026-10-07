import Foundation

public struct LogEntry: Identifiable, Sendable {
    public let id: Int
    public let line: String
    public let level: LineLevel

    public init(id: Int, line: String) {
        self.id = id
        self.line = line
        self.level = LineLevel.classify(line)
    }
}

/// Classifies a log line for colouring, the way the management tools' own
/// Logs tabs do. They write two forms: the log file's
/// "[yyyy-MM-dd HH:mm:ss] LEVEL message" and the console's "LEVEL: message".
/// Lines in neither form (Munki's "Oct 07 2026 10:00:00 -0700 ERROR: …",
/// Intune's daemon logs) fall back to the level word they carry.
public enum LineLevel: Equatable, Sendable {
    case info, debug, warning, error, success, header

    public static func classify(_ line: String) -> LineLevel {
        if line.contains("[X]") || line.contains("[x]") || line.contains("✗") { return .error }
        if line.contains("[!]") || line.contains("⚠") { return .warning }
        if line.contains("[+]") || line.contains("✓") || line.contains("[SUCCESS]") { return .success }

        let message: Substring
        let level: Substring
        if line.hasPrefix("["), let close = line.range(of: "] ") {
            // Log file: the level is the unbracketed token after the timestamp.
            let rest = line[close.upperBound...]
            let token = rest.prefix { !$0.isWhitespace }
            level = token
            message = rest.dropFirst(token.count).drop { $0.isWhitespace }
        } else if let colon = line.firstIndex(of: ":"), colon > line.startIndex,
                  line[..<colon].allSatisfy({ $0.isUppercase }) {
            // Console: "INFO: message", "ERROR: message".
            level = line[..<colon]
            message = line[line.index(after: colon)...].drop { $0.isWhitespace }
        } else {
            return plainLevel(line[...])
        }

        switch level {
        case "ERROR", "FAULT", "CRITICAL": return .error
        case "WARN", "WARNING": return .warning
        case "DEBUG", "TRACE": return .debug
        case "SUCCESS": return .success
        default: return plainLevel(message)
        }
    }

    private static func plainLevel(_ message: Substring) -> LineLevel {
        if message.hasPrefix("===") || message.hasPrefix("###") { return .header }
        if message.contains("ERROR:") || message.contains(" | Error | ") { return .error }
        if message.contains("WARNING:") || message.contains(" | Warning | ") { return .warning }
        if message.contains("DEBUG:") || message.contains(" | Verbose | ") { return .debug }
        return .info
    }
}
