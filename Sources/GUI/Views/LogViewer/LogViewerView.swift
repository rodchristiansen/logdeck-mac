import SwiftUI
import Core

struct LogViewerView: View {
    let source: LogSource
    @State private var tailer = LogTailer()
    @State private var searchText = ""
    @State private var isAutoScrolling = false
    @AppStorage("logFontSize") private var logFontSize = 11.0
    @AppStorage("autoTail") private var autoTail = true

    private var filteredEntries: [LogEntry] {
        guard !searchText.isEmpty else { return tailer.entries }
        return tailer.entries.filter { $0.line.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
            Divider()
            footer
        }
        .navigationTitle(source.label)
        .task(id: source.id) {
            isAutoScrolling = autoTail
            tailer.start(source: source)
        }
        .onDisappear {
            tailer.stop()
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "line.3.horizontal.decrease")
                .foregroundStyle(.secondary)
            TextField("Filter log…", text: $searchText)
                .textFieldStyle(.roundedBorder)
            Toggle(isOn: $isAutoScrolling) {
                Image(systemName: "arrow.down.to.line")
            }
            .toggleStyle(.button)
            .help("Follow new lines")
            ActionButtons(source: source)
        }
        .padding(.horizontal)
        .frame(minHeight: 38)
    }

    @ViewBuilder
    private var content: some View {
        switch tailer.state {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .denied(let path):
            EmptyPane(
                title: "Can't Read This Log",
                systemImage: "lock.doc",
                message: "\(path) is readable by root only."
            )
        case .missing(let path):
            EmptyPane(
                title: "Log Not Found",
                systemImage: "doc.questionmark",
                message: "\(path) is no longer there. Refresh the list to rescan."
            )
        case .failed(let reason):
            EmptyPane(title: "Couldn't Read This Log", systemImage: "exclamationmark.triangle", message: reason)
        case .loaded where tailer.entries.isEmpty:
            EmptyPane(
                title: "Empty Log",
                systemImage: "doc",
                message: "Nothing has been written to this log yet. New lines appear as they are written."
            )
        case .loaded:
            lines
        }
    }

    private var lines: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 1) {
                    ForEach(filteredEntries) { entry in
                        LogLineView(entry: entry, searchText: searchText, fontSize: logFontSize)
                            .id(entry.id)
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .textSelection(.enabled)
            .background(.black.opacity(0.85))
            .onChange(of: tailer.entries.count) {
                if isAutoScrolling, let last = filteredEntries.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
            .onChange(of: isAutoScrolling) { _, follow in
                if follow, let last = filteredEntries.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Text(source.resolvedPath)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)
            Spacer()
            Text(searchText.isEmpty ? "\(tailer.entries.count) lines" : "\(filteredEntries.count) of \(tailer.entries.count) lines")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
            if let size = source.fileSize {
                Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}
