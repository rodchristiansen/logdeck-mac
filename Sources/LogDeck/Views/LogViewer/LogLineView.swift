import SwiftUI

struct LogLineView: View {
    let entry: LogEntry
    let searchText: String

    var body: some View {
        Text(entry.line)
            .font(.system(size: 11, design: .monospaced))
            .foregroundStyle(severityColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 0.5)
            .padding(.horizontal, 4)
            .background(backgroundColor)
            .contentShape(Rectangle())
    }

    private var severityColor: Color {
        switch entry.severity {
        case .error: .red
        case .warning: .orange
        case .debug: .secondary
        case .info: .primary
        }
    }

    private var backgroundColor: Color {
        if !searchText.isEmpty && entry.line.localizedStandardContains(searchText) {
            return .accentColor.opacity(0.1)
        }
        return .clear
    }
}
