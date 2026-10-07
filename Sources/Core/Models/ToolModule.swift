import Foundation

public protocol ToolModule: Identifiable, Sendable {
    var id: String { get }
    var name: String { get }
    /// What the tool does, as its suite bucket names it: Bootstrap, Reports, …
    var role: String { get }
    var icon: String { get }
    var category: ToolCategory { get }
    var detectionPaths: [String] { get }
    /// Folders scanned for logs, listed newest first.
    var logDirectories: [LogDirectory] { get }
    /// Individual log files at fixed paths.
    var logSources: [LogSource] { get }
    var supportPaths: [SupportPath] { get }
    var isInstalled: Bool { get }
}

extension ToolModule {
    public var isInstalled: Bool {
        detectionPaths.contains {
            FileManager.default.fileExists(atPath: ($0 as NSString).expandingTildeInPath)
        }
    }

    /// The folder to open from "Open log folder": the first scanned folder, or
    /// the folder holding the first fixed log.
    public var primaryLogFolder: String? {
        if let directory = logDirectories.first { return directory.resolvedPath }
        return logSources.first.map { ($0.resolvedPath as NSString).deletingLastPathComponent }
    }
}

public enum ToolCategory: String, CaseIterable, Sendable {
    case managementTools = "Management Tools"
    case mdm = "MDM & Endpoint"
    case scripting = "Scripts"
}
