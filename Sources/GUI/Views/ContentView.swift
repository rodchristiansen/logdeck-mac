import SwiftUI
import Core

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.scenePhase) private var scenePhase
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 230, max: 320)
        } content: {
            Group {
                if let module = appState.selectedModule {
                    LogSourceListView(module: module)
                } else {
                    EmptyPane(
                        title: "Select a Tool",
                        systemImage: "sidebar.left",
                        message: "Choose a tool from the sidebar to see its logs."
                    )
                }
            }
            .navigationSplitViewColumnWidth(min: 260, ideal: 300, max: 460)
        } detail: {
            Group {
                if let source = appState.selectedLogSource {
                    LogViewerView(source: source)
                } else if let module = appState.selectedModule,
                          let logs = appState.logs[module.id], logs.isEmpty {
                    EmptyLogsView(module: module, logs: logs)
                } else {
                    EmptyPane(
                        title: "Select a Log",
                        systemImage: "doc.text",
                        message: "Choose a log to view its contents."
                    )
                }
            }
            // Keep the detail column from collapsing when it has nothing to show.
            .frame(minWidth: 420, maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 960, minHeight: 520)
        .task {
            appState.detectTools()
            await appState.refreshLogs()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await appState.refreshLogs() }
            }
        }
    }
}

/// A placeholder that fills its pane, so an empty column keeps its width.
struct EmptyPane: View {
    let title: String
    let systemImage: String
    let message: String

    var body: some View {
        ContentUnavailableView(title, systemImage: systemImage, description: Text(message))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// What a tool with nothing to show says, and why.
struct EmptyLogsView: View {
    let module: any ToolModule
    let logs: ModuleLogs

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        } actions: {
            if let folder = module.primaryLogFolder, FileManager.default.fileExists(atPath: folder) {
                Button("Open Log Folder") {
                    NSWorkspace.shared.open(URL(fileURLWithPath: folder))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var title: String {
        if !logs.unreadableFolders.isEmpty { return "Can't Read \(module.name) Logs" }
        return module.isInstalled ? "No \(module.name) Logs Yet" : "\(module.name) Not Installed"
    }

    private var systemImage: String {
        if !logs.unreadableFolders.isEmpty { return "lock.doc" }
        return module.isInstalled ? "doc.text.magnifyingglass" : "shippingbox"
    }

    private var message: String {
        let folder = module.primaryLogFolder ?? ""
        if let unreadable = logs.unreadableFolders.first {
            return "\(unreadable.resolvedPath) exists but only root can list it."
        }
        if module.isInstalled {
            return "\(module.name) has not written anything to \(folder) yet. Its logs appear here after its first run."
        }
        return "\(module.name) was not found on this Mac, and \(folder) holds no logs."
    }
}
