import Foundation

public struct LogSource: Identifiable, Hashable, Sendable {
    public let id: String
    public let label: String
    public let path: String
    public let requiresPrivilege: Bool
    public let format: LogFormat
    public let rotationPattern: String?

    public init(
        id: String,
        label: String,
        path: String,
        requiresPrivilege: Bool = false,
        format: LogFormat = .plainText,
        rotationPattern: String? = nil
    ) {
        self.id = id
        self.label = label
        self.path = path
        self.requiresPrivilege = requiresPrivilege
        self.format = format
        self.rotationPattern = rotationPattern
    }

    public var resolvedPath: String {
        (path as NSString).expandingTildeInPath
    }

    public var exists: Bool {
        if rotationPattern != nil {
            return !resolvedFiles.isEmpty
        }
        return FileManager.default.fileExists(atPath: resolvedPath)
    }

    public var resolvedFiles: [String] {
        guard let pattern = rotationPattern else {
            return FileManager.default.fileExists(atPath: resolvedPath) ? [resolvedPath] : []
        }
        let directory = (resolvedPath as NSString).deletingLastPathComponent
        guard let contents = try? FileManager.default.contentsOfDirectory(atPath: directory) else {
            return []
        }
        let baseName = (resolvedPath as NSString).lastPathComponent
        let regex = try? NSRegularExpression(pattern: pattern)
        return contents
            .filter { name in
                guard let regex else { return name.hasPrefix(baseName) }
                return regex.firstMatch(
                    in: name,
                    range: NSRange(name.startIndex..., in: name)
                ) != nil
            }
            .map { (directory as NSString).appendingPathComponent($0) }
            .sorted()
    }

    public var fileSize: Int64? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: resolvedPath) else {
            return nil
        }
        return attributes[.size] as? Int64
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
