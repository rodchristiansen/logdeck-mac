import SwiftUI
import LogDeckCore

struct LogViewerView: View {
    let source: LogSource
    @State private var tailer = LogTailer()
    @State private var searchText = ""
    @State private var isAutoScrolling = true
    @State private var scrollProxy: ScrollViewProxy?

    private var filteredEntries: [LogEntry] {
        if searchText.isEmpty {
            return tailer.entries
        }
        return tailer.entries.filter {
            $0.line.localizedStandardContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            logContent
            Divider()
            toolbar
        }
        .navigationTitle(source.label)
        .task(id: source.id) {
            tailer.start(source: source)
        }
        .onDisappear {
            tailer.stop()
        }
    }

    private var logContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(filteredEntries) { entry in
                        LogLineView(entry: entry, searchText: searchText)
                            .id(entry.id)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .font(.system(.body, design: .monospaced))
            .textSelection(.enabled)
            .onChange(of: tailer.entries.count) {
                if isAutoScrolling, let lastEntry = filteredEntries.last {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(lastEntry.id, anchor: .bottom)
                    }
                }
            }
            .onAppear { scrollProxy = proxy }
        }
    }

    @ViewBuilder
    private var toolbar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Filter", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.quaternary, in: .rect(cornerRadius: 6))

            Spacer()

            Text("\(filteredEntries.count) lines")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()

            if let size = source.fileSize {
                Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()
                .frame(height: 16)

            Toggle(isOn: $isAutoScrolling) {
                Image(systemName: "arrow.down.to.line")
            }
            .toggleStyle(.button)
            .controlSize(.small)
            .help("Auto-scroll to bottom")

            ActionButtons(source: source)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
