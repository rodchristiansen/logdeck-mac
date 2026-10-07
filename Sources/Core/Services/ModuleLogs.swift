import Foundation

/// Everything a module has on disk right now: each scanned folder with its
/// sessions, and the fixed log files. Built off the main thread and handed to
/// the views and the CLI as a value.
public struct ModuleLogs: Sendable {
    public struct Folder: Identifiable, Sendable {
        public let directory: LogDirectory
        public let status: LogDirectory.Status
        public let sessions: [LogSession]
        public var id: String { directory.id }
    }

    public let moduleID: String
    public let folders: [Folder]
    public let files: [LogSource]

    public init(module: any ToolModule, fileManager fm: FileManager = .default) {
        moduleID = module.id
        folders = module.logDirectories.map { directory in
            let status = directory.status(fileManager: fm)
            return Folder(
                directory: directory,
                status: status,
                sessions: status == .available ? directory.sessions(fileManager: fm) : []
            )
        }
        files = module.logSources
    }

    public var existingFiles: [LogSource] { files.filter(\.exists) }

    /// Whether anything at all can be shown.
    public var isEmpty: Bool {
        folders.allSatisfy(\.sessions.isEmpty) && existingFiles.isEmpty
    }

    /// Folders that exist but this user cannot list.
    public var unreadableFolders: [LogDirectory] {
        folders.filter { $0.status == .unreadable }.map(\.directory)
    }

    /// The log to open first: the newest session of the first folder that has
    /// one, else the first fixed file that exists.
    public var newest: LogSource? {
        if let session = folders.lazy.compactMap(\.sessions.first).first {
            return session.source
        }
        return existingFiles.first
    }
}
