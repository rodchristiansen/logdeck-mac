import SwiftUI
import Core

struct LogLineView: View {
    let entry: LogEntry
    let searchText: String
    let fontSize: Double

    var body: some View {
        Text(entry.line.isEmpty ? " " : entry.line)
            .font(.system(size: fontSize, design: .monospaced))
            .foregroundStyle(entry.level.color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 0.5)
            .padding(.horizontal, 4)
            .background(highlight)
    }

    private var highlight: Color {
        if !searchText.isEmpty && entry.line.localizedCaseInsensitiveContains(searchText) {
            return .yellow.opacity(0.18)
        }
        return .clear
    }
}

extension LineLevel {
    /// The colours the management tools' own Logs tabs use, on a dark background.
    var color: Color {
        switch self {
        case .error: .red
        case .warning: .orange
        case .success: .green
        case .debug: .gray
        case .header: .cyan
        case .info: .white
        }
    }
}
