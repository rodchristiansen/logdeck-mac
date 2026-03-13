import SwiftUI

@main
struct LogDeckApp: App {
    @State private var appState = AppState()

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
