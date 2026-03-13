import Foundation

@MainActor
@Observable
final class LogTailer {
    private(set) var entries: [LogEntry] = []
    private(set) var isActive = false

    private let reader = LogReader()
    private var tailTask: Task<Void, Never>?
    private var currentOffset: UInt64 = 0

    func start(source: LogSource) {
        stop()
        isActive = true
        entries = []
        currentOffset = 0

        tailTask = Task { [weak self] in
            guard let self else { return }

            // Initial read
            do {
                let initialEntries = try await reader.readLog(from: source)
                guard !Task.isCancelled else { return }
                entries = initialEntries
                let path = source.resolvedPath
                if let attributes = try? FileManager.default.attributesOfItem(atPath: path),
                   let size = attributes[.size] as? UInt64 {
                    currentOffset = size
                }
            } catch {
                entries = [LogEntry(id: 0, line: "Error reading log: \(error.localizedDescription)")]
                return
            }

            // Poll for new content
            while !Task.isCancelled && isActive {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { break }

                do {
                    let (newEntries, newOffset) = try await reader.readTail(from: source, offset: currentOffset)
                    guard !Task.isCancelled else { break }
                    if !newEntries.isEmpty {
                        let baseID = entries.count
                        let reindexed = newEntries.enumerated().map {
                            LogEntry(id: baseID + $0.offset, line: $0.element.line)
                        }
                        entries.append(contentsOf: reindexed)
                        currentOffset = newOffset
                    }
                } catch {
                    break
                }
            }
        }
    }

    func stop() {
        tailTask?.cancel()
        tailTask = nil
        isActive = false
    }
}
