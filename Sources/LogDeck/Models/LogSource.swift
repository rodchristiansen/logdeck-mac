import Foundation

struct LogSource: Identifiable, Hashable, Sendable {
    let id: String
    let label: String
    let path: String
    let requiresPrivilege: Bool
    let format: LogFormat
    let rotationPattern: String?

    init(
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

    var resolvedPath: String {
        (path as NSString).expandingTildeInPath
    }

    var exists: Bool {
        if rotationPattern != nil {
            return !resolvedFiles.isEmpty
        }
        return FileManager.default.fileExists(atPath: resolvedPath)
    }

    var resolvedFiles: [String] {
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

    var fileSize: Int64? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: resolvedPath) else {
            return nil
        }
        return attributes[.size] as? Int64
    }

    var modificationDate: Date? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: resolvedPath) else {
            return nil
        }
        return attributes[.modificationDate] as? Date
    }
}

enum LogFormat: String, Sendable {
    case plainText
    case json
    case plist
    case unifiedLog
}
