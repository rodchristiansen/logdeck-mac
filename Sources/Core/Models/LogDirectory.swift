import Foundation

/// A tool's logs folder, scanned the way that tool's own Logs tab scans it.
///
/// The management tools share one layout under `/Library/Managed <Bucket>/logs`:
///
/// - a session directory per run, `YYYY-MM-DD/HHMMSS/` (`HHMM/` for Munki, with
///   `_2` … `_9` when two runs start together), holding the human log beside
///   `events.jsonl` and `session.json`;
/// - or one directory per day, `YYYY-MM-DD/`, holding the day's log and its
///   rolled generations (`dialog.log.1` …);
/// - and flat files at the root: a current log, its daily rolls
///   (`crypt-YYYY-MM-DD.log`), numbered generations and launchd output.
///
/// Every log found becomes a `LogSession`, listed newest first.
public struct LogDirectory: Identifiable, Hashable, Sendable {
    public let id: String
    public let label: String
    /// Candidate spellings of the folder; the first that exists is scanned.
    public let paths: [String]
    /// The log to open inside a session or day directory, in order of preference.
    /// When none is present the first `*.log` there is used.
    public let sessionLogNames: [String]
    /// Whether loose files at the root are listed as well.
    public let includesFlatFiles: Bool
    /// Which loose files count as logs.
    public let flatFilePattern: String
    /// A current log that always leads the list, as crypt.log does in its tool.
    public let pinnedName: String?

    public init(
        id: String,
        label: String,
        paths: [String],
        sessionLogNames: [String] = [],
        includesFlatFiles: Bool = true,
        flatFilePattern: String = #"\.log(\.\d+)?$"#,
        pinnedName: String? = nil
    ) {
        self.id = id
        self.label = label
        self.paths = paths
        self.sessionLogNames = sessionLogNames
        self.includesFlatFiles = includesFlatFiles
        self.flatFilePattern = flatFilePattern
        self.pinnedName = pinnedName
    }

    public var path: String { paths.first ?? "" }

    public var resolvedPath: String {
        let candidates = paths.map { ($0 as NSString).expandingTildeInPath }
        return candidates.first { FileManager.default.fileExists(atPath: $0) } ?? candidates.first ?? ""
    }

    public enum Status: Equatable, Sendable {
        /// The folder is not there: the tool has never run, or is not installed.
        case missing
        /// The folder is there but this user cannot list it.
        case unreadable
        case available
    }

    public func status(fileManager fm: FileManager = .default) -> Status {
        let root = resolvedPath
        var isDirectory: ObjCBool = false
        guard fm.fileExists(atPath: root, isDirectory: &isDirectory), isDirectory.boolValue else {
            return .missing
        }
        return fm.isReadableFile(atPath: root) && fm.isExecutableFile(atPath: root) ? .available : .unreadable
    }

    /// Every log under the folder, newest first.
    public func sessions(fileManager fm: FileManager = .default) -> [LogSession] {
        let root = resolvedPath
        guard let entries = try? fm.contentsOfDirectory(atPath: root) else { return [] }
        let flatRegex = try? NSRegularExpression(pattern: flatFilePattern)

        var found: [LogSession] = []
        for entry in entries where !entry.hasPrefix(".") {
            let entryPath = (root as NSString).appendingPathComponent(entry)
            var isDirectory: ObjCBool = false
            guard fm.fileExists(atPath: entryPath, isDirectory: &isDirectory) else { continue }

            if isDirectory.boolValue {
                guard let day = LogStamp.parseDay(entry) else { continue }
                found += dayEntries(day: entry, date: day, path: entryPath, fm: fm)
            } else if includesFlatFiles, matches(flatRegex, entry) {
                let modified = (try? fm.attributesOfItem(atPath: entryPath))?[.modificationDate] as? Date
                let stamped = LogStamp.embeddedDate(in: entry)
                found.append(LogSession(
                    id: "\(id)/\(entry)",
                    name: entry,
                    path: entryPath,
                    date: entry == pinnedName ? modified : (stamped?.date ?? modified),
                    hasTime: entry == pinnedName || stamped?.hasTime ?? true,
                    size: LogStamp.fileSize(entryPath, fm),
                    generation: LogStamp.generation(of: entry),
                    isPinned: entry == pinnedName
                ))
            }
        }
        return found.sorted(by: LogSession.newestFirst)
    }

    /// The logs inside one `YYYY-MM-DD/` directory: the day's own log and its
    /// generations, then one entry per run session directory below it.
    private func dayEntries(day: String, date: Date, path dayPath: String, fm: FileManager) -> [LogSession] {
        guard let children = try? fm.contentsOfDirectory(atPath: dayPath) else { return [] }
        var found: [LogSession] = []

        for child in children where !child.hasPrefix(".") {
            let childPath = (dayPath as NSString).appendingPathComponent(child)
            var isDirectory: ObjCBool = false
            guard fm.fileExists(atPath: childPath, isDirectory: &isDirectory) else { continue }

            if isDirectory.boolValue {
                guard let files = try? fm.contentsOfDirectory(atPath: childPath),
                      let log = preferredLog(in: files) else { continue }
                let stamp = "\(day)-\(child)"
                let path = (childPath as NSString).appendingPathComponent(log)
                found.append(LogSession(
                    id: "\(id)/\(day)/\(child)",
                    name: stamp,
                    path: path,
                    date: LogStamp.parseSession(stamp) ?? date,
                    hasTime: LogStamp.parseSession(stamp) != nil,
                    size: LogStamp.fileSize(path, fm),
                    generation: 0,
                    isPinned: false
                ))
            } else if isDayLog(child) {
                let generation = LogStamp.generation(of: child)
                found.append(LogSession(
                    id: "\(id)/\(day)/\(child)",
                    name: generation == 0 && sessionLogNames.contains(child) ? day : "\(day) (\(child))",
                    path: childPath,
                    date: date,
                    hasTime: false,
                    size: LogStamp.fileSize(childPath, fm),
                    generation: generation,
                    isPinned: false
                ))
            }
        }
        return found
    }

    private func preferredLog(in files: [String]) -> String? {
        for name in sessionLogNames where files.contains(name) {
            return name
        }
        return files.sorted().first { $0.hasSuffix(".log") }
    }

    /// A day directory's own log: one of `sessionLogNames` or a numbered
    /// generation of one, or any `*.log` when no names are given.
    private func isDayLog(_ name: String) -> Bool {
        if sessionLogNames.isEmpty { return name.hasSuffix(".log") }
        return sessionLogNames.contains { name == $0 || LogStamp.isGeneration(name, of: $0) }
    }

    private func matches(_ regex: NSRegularExpression?, _ name: String) -> Bool {
        guard let regex else { return name.hasSuffix(".log") }
        return regex.firstMatch(in: name, range: NSRange(name.startIndex..., in: name)) != nil
    }
}

/// One log found in a `LogDirectory`: a run, a day, or a loose file.
public struct LogSession: Identifiable, Hashable, Sendable {
    public let id: String
    /// The stamp or file name, as the tool's own Logs tab shows it.
    public let name: String
    public let path: String
    public let date: Date?
    /// False when the date is only a day (a day directory, a daily roll).
    public let hasTime: Bool
    public let size: Int64
    /// 0 for a current log, N for its `.N` rolled generation.
    public let generation: Int
    public let isPinned: Bool

    public init(
        id: String,
        name: String,
        path: String,
        date: Date?,
        hasTime: Bool,
        size: Int64,
        generation: Int = 0,
        isPinned: Bool = false
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.date = date
        self.hasTime = hasTime
        self.size = size
        self.generation = generation
        self.isPinned = isPinned
    }

    public var displayDate: String {
        guard let date else { return name }
        return date.formatted(date: .abbreviated, time: hasTime ? .shortened : .omitted)
    }

    public var displaySize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    /// The file as a source the viewer can read and tail.
    public var source: LogSource {
        LogSource(id: id, label: displayDate, path: path)
    }

    /// Pinned first, then newest; within one date the current log leads its
    /// rolled generations, and later names lead earlier ones.
    public static func newestFirst(_ lhs: LogSession, _ rhs: LogSession) -> Bool {
        if lhs.isPinned != rhs.isPinned { return lhs.isPinned }
        let l = lhs.date ?? .distantPast
        let r = rhs.date ?? .distantPast
        if l != r { return l > r }
        if lhs.generation != rhs.generation { return lhs.generation < rhs.generation }
        return lhs.name > rhs.name
    }
}

/// Parsing for the stamps the tools put in folder and file names.
public enum LogStamp {
    private static func formatter(_ format: String) -> DateFormatter {
        let f = DateFormatter()
        f.dateFormat = format
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }

    /// `YYYY-MM-DD`, the day directory name.
    public static func parseDay(_ name: String) -> Date? {
        guard name.count == 10 else { return nil }
        return formatter("yyyy-MM-dd").date(from: name)
    }

    /// `YYYY-MM-DD-HHMMSS`, or `YYYY-MM-DD-HHMM` for Munki. A same-second
    /// suffix (`_2` … `_9`) is ignored.
    public static func parseSession(_ stamp: String) -> Date? {
        var base = stamp
        if let underscore = stamp.lastIndex(of: "_"),
           stamp[stamp.index(after: underscore)...].allSatisfy(\.isNumber) {
            base = String(stamp[..<underscore])
        }
        return formatter("yyyy-MM-dd-HHmmss").date(from: base)
            ?? formatter("yyyy-MM-dd-HHmm").date(from: base)
    }

    /// A stamp inside a file name: `2026-10-07-142530.log` (a run that could
    /// not get its session directory) or `crypt-2026-10-05.log` (a daily roll).
    public static func embeddedDate(in name: String) -> (date: Date, hasTime: Bool)? {
        let pattern = #"(\d{4}-\d{2}-\d{2})(?:-(\d{6}|\d{4}))?"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: name, range: NSRange(name.startIndex..., in: name)),
              let dayRange = Range(match.range(at: 1), in: name) else { return nil }
        let day = String(name[dayRange])
        if let timeRange = Range(match.range(at: 2), in: name),
           let date = parseSession("\(day)-\(name[timeRange])") {
            return (date, true)
        }
        return parseDay(day).map { ($0, false) }
    }

    /// N for `name.N`, 0 otherwise.
    public static func generation(of name: String) -> Int {
        guard let dot = name.lastIndex(of: ".") else { return 0 }
        return Int(name[name.index(after: dot)...]) ?? 0
    }

    public static func isGeneration(_ name: String, of base: String) -> Bool {
        name.hasPrefix(base + ".") && Int(name.dropFirst(base.count + 1)) != nil
    }

    static func fileSize(_ path: String, _ fm: FileManager) -> Int64 {
        ((try? fm.attributesOfItem(atPath: path))?[.size] as? NSNumber)?.int64Value ?? 0
    }
}
