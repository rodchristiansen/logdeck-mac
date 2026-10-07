import SwiftUI
import Core

struct ToolRowView: View {
    let module: any ToolModule
    let logs: ModuleLogs?

    private var count: Int {
        guard let logs else { return 0 }
        return logs.folders.reduce(0) { $0 + $1.sessions.count } + logs.existingFiles.count
    }

    var body: some View {
        Label {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(module.name)
                    Text(module.role)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if count > 0 {
                    Text("\(count)")
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                Image(systemName: "circle.fill")
                    .font(.system(size: 6))
                    .foregroundStyle(module.isInstalled ? .green : .secondary)
                    .help(module.isInstalled ? "Installed" : "Not detected")
            }
        } icon: {
            Image(systemName: module.icon)
        }
        .opacity(module.isInstalled || count > 0 ? 1.0 : 0.6)
    }
}
