import SwiftUI
import Core

struct LogSourceListView: View {
    let module: any ToolModule
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState
        List(selection: $state.selectedLogSource) {
            if !module.logSources.isEmpty {
                Section("Logs") {
                    ForEach(module.logSources) { source in
                        LogSourceRow(source: source)
                            .tag(source)
                    }
                }
            }

            if !module.supportPaths.isEmpty {
                Section("Support Files") {
                    ForEach(module.supportPaths) { path in
                        SupportPathRow(path: path)
                    }
                }
            }
        }
        .navigationTitle(module.name)
    }
}

private struct LogSourceRow: View {
    let source: LogSource

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Label(source.label, systemImage: iconName)
                Spacer()
                if source.requiresPrivilege {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .help("Requires elevated privileges")
                }
            }
            Text(source.path)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)

            if let size = source.fileSize {
                Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }

    private var iconName: String {
        if !source.exists {
            return "doc.questionmark"
        }
        switch source.format {
        case .plainText: return "doc.text"
        case .json: return "curlybraces"
        case .plist: return "list.bullet.rectangle"
        case .unifiedLog: return "text.magnifyingglass"
        }
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
                    revealInFinder(path: path.resolvedPath)
                } label: {
                    Image(systemName: "folder")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .help("Reveal in Finder")
            }
        }
        .opacity(path.exists ? 1.0 : 0.5)
        .padding(.vertical, 2)
    }

    private var supportIcon: String {
        switch path.kind {
        case .configuration: "gearshape"
        case .cache: "archivebox"
        case .binary: "terminal"
        case .scripts: "scroll"
        case .data: "folder"
        }
    }

    private func revealInFinder(path: String) {
        NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
    }
}
