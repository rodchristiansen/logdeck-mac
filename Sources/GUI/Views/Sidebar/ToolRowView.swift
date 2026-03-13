import SwiftUI
import Core

struct ToolRowView: View {
    let module: any ToolModule
    @Environment(AppState.self) private var appState

    private var isEnabled: Bool {
        appState.enabledModuleIDs.contains(module.id)
    }

    var body: some View {
        Label {
            HStack {
                Text(module.name)
                Spacer()
                if module.isInstalled {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .foregroundStyle(.green)
                        .help("Installed")
                } else {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .foregroundStyle(.secondary)
                        .help("Not detected")
                }
            }
        } icon: {
            Image(systemName: module.icon)
                .foregroundStyle(isEnabled ? .primary : .secondary)
        }
        .opacity(isEnabled ? 1.0 : 0.5)
    }
}
