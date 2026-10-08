import Foundation

/// Everything a module has on disk right now: each scanned folder with its
/// sessions, and the fixed log files. Built off the main thread and handed to
/// the views and the CLI as a value.
///
/// A `/Library/Managed <Bucket>/logs` folder is followed by this user's
/// `~/Library/Logs/Managed <Bucket>` when that folder exists, so every bucket
/// shows its user-context runs beside root's without the module listing them.
public struct ModuleLogs: Sendable {
    public struct Folder: Identifiable, Sendable {
        public let directory: LogDirectory
        public let status: LogDirectory.Status
        public let sessions: [LogSession]
        /// The module folder this one belongs to: its own id for a system
        /// folder, the system folder's id for this user's counterpart.
        public let groupID: String
        /// Whether the group holds both root's folder and this user's.
        public let hasUserCounterpart: Bool
        public var id: String { directory.id }
        public var origin: LogDirectory.Origin { directory.origin }
    }

    public let moduleID: String
    public let folders: [Folder]
    public let files: [LogSource]

    public init(
        module: any ToolModule,
        fileManager fm: FileManager = .default,
        home: String = FileManager.default.homeDirectoryForCurrentUser.path
    ) {
        moduleID = module.id
        folders = Self.scan(module.logDirectories, fileManager: fm, home: home)
        files = module.logSources
    }

    /// Each folder, followed by this user's counterpart when it exists.
    public static func scan(_ directories: [LogDirectory], fileManager fm: FileManager = .default, home: String) -> [Folder] {
        directories.flatMap { directory -> [Folder] in
            let user = directory.userDirectory(home: home).flatMap { candidate -> (LogDirectory, LogDirectory.Status)? in
                let status = candidate.status(fileManager: fm)
                return status == .missing ? nil : (candidate, status)
            }
            var group = [folder(directory, directory.status(fileManager: fm), groupID: directory.id, paired: user != nil, fm)]
            if let (candidate, status) = user {
                group.append(folder(candidate, status, groupID: directory.id, paired: true, fm))
            }
            return group
        }
    }

    private static func folder(_ directory: LogDirectory, _ status: LogDirectory.Status, groupID: String, paired: Bool, _ fm: FileManager) -> Folder {
        Folder(
            directory: directory,
            status: status,
            sessions: status == .available ? directory.sessions(fileManager: fm) : [],
            groupID: groupID,
            hasUserCounterpart: paired
        )
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

    /// The log to open first: the newest session of the first folder group
    /// that has one, root's and this user's together, else the first fixed
    /// file that exists.
    public var newest: LogSource? {
        var seen: [String] = []
        for folder in folders where !seen.contains(folder.groupID) {
            seen.append(folder.groupID)
            let sessions = folders.filter { $0.groupID == folder.groupID }.flatMap(\.sessions)
            if let first = sessions.sorted(by: LogSession.newestFirst).first {
                return first.source
            }
        }
        return existingFiles.first
    }
}
