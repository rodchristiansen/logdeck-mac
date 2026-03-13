import Foundation

public struct SupportPath: Identifiable, Hashable, Sendable {
    public let id: String
    public let label: String
    public let path: String
    public let kind: SupportPathKind

    public init(id: String, label: String, path: String, kind: SupportPathKind) {
        self.id = id
        self.label = label
        self.path = path
        self.kind = kind
    }

    public var resolvedPath: String {
        (path as NSString).expandingTildeInPath
    }

    public var exists: Bool {
        FileManager.default.fileExists(atPath: resolvedPath)
    }
}

public enum SupportPathKind: String, Sendable {
    case configuration
    case cache
    case binary
    case scripts
    case data
}
