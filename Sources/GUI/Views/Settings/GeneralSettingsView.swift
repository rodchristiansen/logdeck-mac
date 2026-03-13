import SwiftUI
import Core

struct GeneralSettingsView: View {
    @AppStorage("autoTail") private var autoTail = true
    @AppStorage("maxLogLines") private var maxLogLines = 50_000
    @AppStorage("logFontSize") private var logFontSize = 11.0

    var body: some View {
        Form {
            Section("Log Viewer") {
                Toggle("Auto-tail new logs on open", isOn: $autoTail)

                Picker("Max visible lines", selection: $maxLogLines) {
                    Text("10,000").tag(10_000)
                    Text("25,000").tag(25_000)
                    Text("50,000").tag(50_000)
                    Text("100,000").tag(100_000)
                }

                HStack {
                    Text("Font size")
                    Slider(value: $logFontSize, in: 9...16, step: 1)
                    Text("\(Int(logFontSize)) pt")
                        .monospacedDigit()
                        .frame(width: 40)
                }
            }

            Section("Detection") {
                Text("LogDeck scans known filesystem paths to detect installed tools. Re-detection happens automatically when the app becomes active.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}
