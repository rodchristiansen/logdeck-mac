import SwiftUI
import Core

/// The middle column: a tool's logs, each scanned folder newest first (the way
/// the tool's own Logs tab lists them), with this user's runs under their own
/// "This user" heading beside root's, then its fixed log files and support paths.
struct LogSourceListView: View {
    let module: any ToolModule
    @Environment(AppState.self) private var appState

    private var logs: ModuleLogs? { appState.logs[module.id] }

    var body: some View {
        @Bindable var state = appState
        List(selection: $state.selectedLogSource) {
            if let logs {
                ForEach(logs.folders) { folder in
                    Section {
                        if folder.sessions.isEmpty {
                            FolderStatusRow(folder: folder)
                        } else {
                            ForEach(folder.sessions) { session in
                                SessionRow(session: session)
                                    .tag(session.source)
                            }
                        }
                    } header: {
                        HStack {
                            Text(heading(for: folder))
                            Spacer()
                            if !folder.sessions.isEmpty {
                                Text("\(folder.sessions.count)")
                                    .monospacedDigit()
                            }
                        }
                    }
                }

                let files = logs.files.filter { $0.exists || !$0.path.hasPrefix("~") }
                if !files.isEmpty {
                    Section(logs.folders.isEmpty ? "Logs" : "Other Logs") {
                        ForEach(files) { source in
                            LogFileRow(source: source)
                                .tag(source)
                                .selectionDisabled(!source.exists)
                        }
                    }
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }

            if !module.supportPaths.isEmpty {
                Section("Support Files") {
                    ForEach(module.supportPaths) { path in
                        SupportPathRow(path: path)
                            .selectionDisabled()
                    }
                }
            }
        }
        .navigationTitle(module.name)
        .navigationSubtitle(module.role)
        .toolbar {
            ToolbarItemGroup {
                Button {
                    if let folder = module.primaryLogFolder {
                        NSWorkspace.shared.open(URL(fileURLWithPath: folder))
                    }
                } label: {
                    Label("Open Log Folder", systemImage: "folder")
                }
                .help("Open the log folder in Finder")
                .disabled(module.primaryLogFolder.map { !FileManager.default.fileExists(atPath: $0) } ?? true)

                Button {
                    Task { await appState.refreshLogs() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .help("Rescan the log folders")
                .keyboardShortcut("r")
            }
        }
    }
}

/// A folder's section title. Where a bucket has both root's folder and this
/// user's, the two read as the tools' own Logs tabs head them.
private func heading(for folder: ModuleLogs.Folder) -> String {
    guard folder.hasUserCounterpart else { return folder.directory.label }
    switch folder.origin {
    case .system: return folder.origin.label
    case .user: return "\(folder.origin.label) (\(NSUserName()))"
    }
}

private struct SessionRow: View {
    let session: LogSession

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.displayDate)
                Text(session.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            Text(session.displaySize)
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.vertical, 1)
    }
}

private struct FolderStatusRow: View {
    let folder: ModuleLogs.Folder

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(message, systemImage: icon)
                .foregroundStyle(.secondary)
            Text(folder.directory.resolvedPath)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(.vertical, 2)
    }

    private var message: String {
        switch folder.status {
        case .missing: "Folder not found"
        case .unreadable: "Needs root to read"
        case .available: "No logs yet"
        }
    }

    private var icon: String {
        switch folder.status {
        case .missing: "questionmark.folder"
        case .unreadable: "lock"
        case .available: "tray"
        }
    }
}

private struct LogFileRow: View {
    let source: LogSource

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Label(source.label, systemImage: source.exists ? "doc.text" : "doc.questionmark")
                Spacer()
                if source.exists && !source.isReadable {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .help("Needs root to read")
                } else if let size = source.fileSize {
                    Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            Text(source.exists ? source.resolvedPath : source.path)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .opacity(source.exists ? 1.0 : 0.5)
        .padding(.vertical, 1)
    }
}

private struct SupportPathRow: View {
    let path: SupportPath

    var body: some View {
        HStack {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(path.label)
                    Text(path.path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            } icon: {
                Image(systemName: supportIcon)
            }
            Spacer()
            if path.exists {
                Button {
                    NSWorkspace.shared.selectFile(path.resolvedPath, inFileViewerRootedAtPath: "")
                } label: {
                    Image(systemName: "folder")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .help("Reveal in Finder")
            }
        }
        .opacity(path.exists ? 1.0 : 0.5)
        .padding(.vertical, 1)
    }

    private var supportIcon: String {
        switch path.kind {
        case .configuration: "gearshape"
        case .cache: "archivebox"
        case .binary: "app"
        case .scripts: "scroll"
        case .data: "folder"
        }
    }
}
