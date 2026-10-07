import Foundation

@MainActor
@Observable
public final class LogTailer {
    public enum State: Equatable, Sendable {
        case loading
        case loaded
        /// The file is there but this user cannot read it.
        case denied(String)
        case missing(String)
        case failed(String)
    }

    public private(set) var entries: [LogEntry] = []
    public private(set) var isActive = false
    public private(set) var state: State = .loading

    private let reader = LogReader()
    private var tailTask: Task<Void, Never>?
    private var currentOffset: UInt64 = 0

    public init() {}

    public func start(source: LogSource) {
        stop()
        isActive = true
        entries = []
        state = .loading
        currentOffset = 0

        tailTask = Task { [weak self] in
            guard let self else { return }

            do {
                let initialEntries = try await reader.readLog(from: source)
                guard !Task.isCancelled else { return }
                // A trailing newline leaves one empty line; drop it.
                entries = initialEntries.last?.line.isEmpty == true ? Array(initialEntries.dropLast()) : initialEntries
                state = .loaded
                if let size = (try? FileManager.default.attributesOfItem(atPath: source.resolvedPath))?[.size] as? NSNumber {
                    currentOffset = size.uint64Value
                }
            } catch LogReader.ReadError.accessDenied(let path) {
                state = .denied(path)
                return
            } catch LogReader.ReadError.fileNotFound(let path) {
                state = .missing(path)
                return
            } catch {
                state = .failed(error.localizedDescription)
                return
            }

            while !Task.isCancelled && isActive {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { break }

                do {
                    let (newEntries, newOffset) = try await reader.readTail(from: source, offset: currentOffset)
                    guard !Task.isCancelled else { break }
                    if !newEntries.isEmpty {
                        let baseID = (entries.last?.id ?? -1) + 1
                        let reindexed = newEntries.enumerated().map {
                            LogEntry(id: baseID + $0.offset, line: $0.element.line)
                        }
                        entries.append(contentsOf: reindexed)
                    }
                    currentOffset = newOffset
                } catch {
                    break
                }
            }
        }
    }

    public func stop() {
        tailTask?.cancel()
        tailTask = nil
        isActive = false
    }
}
