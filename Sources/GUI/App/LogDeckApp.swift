import SwiftUI
import Core

@main
struct LogDeckApp: App {
    @State private var appState = AppState()

    init() {
        // Builds before this one stored settings under other bundle identifiers.
        Preferences.migrateStandard()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
        .defaultSize(width: 1100, height: 700)

        Settings {
            SettingsView()
                .environment(appState)
        }
    }
}
