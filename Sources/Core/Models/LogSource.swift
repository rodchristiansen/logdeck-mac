import Foundation

/// One log file at a known path, or a file found while scanning a
/// `LogDirectory` (a run session, a day, a rolled generation).
public struct LogSource: Identifiable, Hashable, Sendable {
    public let id: String
    public let label: String
    public let path: String
    /// Other spellings of the same file, tried in order when `path` is missing:
    /// Munki's `Logs/` became `logs/`, and a tool may fall back to ~/Library/Logs.
    public let fallbackPaths: [String]
    public let requiresPrivilege: Bool
    public let format: LogFormat

    public init(
        id: String,
        label: String,
        path: String,
        fallbackPaths: [String] = [],
        requiresPrivilege: Bool = false,
        format: LogFormat = .plainText
    ) {
        self.id = id
        self.label = label
        self.path = path
        self.fallbackPaths = fallbackPaths
        self.requiresPrivilege = requiresPrivilege
        self.format = format
    }

    /// The first candidate path that exists, or the primary path when none does.
    public var resolvedPath: String {
        let candidates = ([path] + fallbackPaths).map { ($0 as NSString).expandingTildeInPath }
        return candidates.first { FileManager.default.fileExists(atPath: $0) } ?? candidates[0]
    }

    public var exists: Bool {
        FileManager.default.fileExists(atPath: resolvedPath)
    }

    public var isReadable: Bool {
        FileManager.default.isReadableFile(atPath: resolvedPath)
    }

    public var fileSize: Int64? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: resolvedPath) else {
            return nil
        }
        return (attributes[.size] as? NSNumber)?.int64Value
    }

    public var modificationDate: Date? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: resolvedPath) else {
            return nil
        }
        return attributes[.modificationDate] as? Date
    }
}

public enum LogFormat: String, Sendable {
    case plainText
    case json
    case plist
    case unifiedLog
}
