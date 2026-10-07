import Foundation

public actor LogReader {
    public enum ReadError: Error, LocalizedError {
        case fileNotFound(String)
        case accessDenied(String)
        case readFailed(String)

        public var errorDescription: String? {
            switch self {
            case .fileNotFound(let path): "File not found: \(path)"
            case .accessDenied(let path): "Access denied: \(path)"
            case .readFailed(let path): "Failed to read: \(path)"
            }
        }
    }

    private let maxReadSize: Int = 10 * 1024 * 1024 // 10 MB initial read limit

    public init() {}

    public func readLog(from source: LogSource) throws -> [LogEntry] {
        let path = source.resolvedPath
        guard FileManager.default.fileExists(atPath: path) else {
            throw ReadError.fileNotFound(path)
        }
        guard FileManager.default.isReadableFile(atPath: path) else {
            throw ReadError.accessDenied(path)
        }

        let url = URL(fileURLWithPath: path)
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }

        // Read from the end if file is large
        let fileSize = try handle.seekToEnd()
        let readOffset: UInt64
        if fileSize > UInt64(maxReadSize) {
            readOffset = fileSize - UInt64(maxReadSize)
            try handle.seek(toOffset: readOffset)
        } else {
            try handle.seek(toOffset: 0)
            readOffset = 0
        }

        guard let data = try handle.readToEnd() else { return [] }
        // Lossy: a read that starts mid-file can land inside a UTF-8 sequence.
        let content = String(decoding: data, as: UTF8.self)

        let lines = content.components(separatedBy: .newlines)
        return lines.enumerated().map { index, line in
            LogEntry(id: index, line: line)
        }
    }

    public func readTail(from source: LogSource, offset: UInt64) throws -> (entries: [LogEntry], newOffset: UInt64) {
        let path = source.resolvedPath
        guard FileManager.default.fileExists(atPath: path) else {
            throw ReadError.fileNotFound(path)
        }

        let url = URL(fileURLWithPath: path)
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }

        let fileSize = try handle.seekToEnd()
        // A file shorter than what was read has been rolled over: start again.
        let start = fileSize < offset ? 0 : offset
        guard fileSize > start else {
            return ([], fileSize)
        }

        try handle.seek(toOffset: start)
        guard let data = try handle.readToEnd() else { return ([], fileSize) }
        let content = String(decoding: data, as: UTF8.self)

        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        let entries = lines.enumerated().map { index, line in
            LogEntry(id: Int(start) + index, line: line)
        }
        return (entries, fileSize)
    }
}
