import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            ModulesSettingsView()
                .tabItem {
                    Label("Modules", systemImage: "puzzlepiece.extension")
                }

            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
        }
        .frame(width: 500, height: 400)
    }
}
