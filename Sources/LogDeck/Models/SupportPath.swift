import Foundation

struct SupportPath: Identifiable, Hashable, Sendable {
    let id: String
    let label: String
    let path: String
    let kind: SupportPathKind

    var resolvedPath: String {
        (path as NSString).expandingTildeInPath
    }

    var exists: Bool {
        FileManager.default.fileExists(atPath: resolvedPath)
    }
}

enum SupportPathKind: String, Sendable {
    case configuration
    case cache
    case binary
    case scripts
    case data
}
