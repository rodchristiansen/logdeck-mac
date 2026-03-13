import SwiftUI
import LogDeckCore

struct SidebarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState
        List(selection: $state.selectedModuleID) {
            ForEach(appState.groupedModules, id: \.0) { category, modules in
                Section(category.rawValue) {
                    ForEach(modules, id: \.id) { module in
                        ToolRowView(module: module)
                            .tag(module.id)
                    }
                }
            }
        }
        .navigationTitle("LogDeck")
        .listStyle(.sidebar)
        .onChange(of: appState.selectedModuleID) {
            appState.selectedLogSource = nil
        }
    }
}
