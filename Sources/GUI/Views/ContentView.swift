import SwiftUI
import Core

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        @Bindable var state = appState
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView()
        } content: {
            if let module = appState.selectedModule {
                LogSourceListView(module: module)
            } else {
                ContentUnavailableView(
                    "Select a Tool",
                    systemImage: "sidebar.left",
                    description: Text("Choose a tool from the sidebar to view its logs.")
                )
            }
        } detail: {
            if let source = appState.selectedLogSource {
                LogViewerView(source: source)
            } else {
                ContentUnavailableView(
                    "Select a Log",
                    systemImage: "doc.text",
                    description: Text("Choose a log source to view its contents.")
                )
            }
        }
        .navigationSplitViewStyle(.balanced)
        .onAppear {
            appState.detectTools()
        }
    }
}
