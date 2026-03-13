import SwiftUI
import LogDeckCore

struct ModulesSettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Form {
            Section {
                Text("Enable or disable tool modules. Installed tools are auto-detected.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            ForEach(appState.groupedModules, id: \.0) { category, modules in
                Section(category.rawValue) {
                    ForEach(modules, id: \.id) { module in
                        ModuleToggleRow(module: module)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}

private struct ModuleToggleRow: View {
    let module: any ToolModule
    @Environment(AppState.self) private var appState

    private var isEnabled: Bool {
        appState.enabledModuleIDs.contains(module.id)
    }

    var body: some View {
        Toggle(isOn: Binding(
            get: { isEnabled },
            set: { _ in appState.toggleModule(module.id) }
        )) {
            HStack {
                Image(systemName: module.icon)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text(module.name)
                    HStack(spacing: 4) {
                        if module.isInstalled {
                            Text("Installed")
                                .font(.caption)
                                .foregroundStyle(.green)
                        } else {
                            Text("Not detected")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text("·")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(module.logSources.count) log sources")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
