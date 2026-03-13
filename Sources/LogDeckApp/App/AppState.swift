import SwiftUI
import LogDeckCore

@MainActor
@Observable
final class AppState {
    var modules: [any ToolModule] = []
    var enabledModuleIDs: Set<String> = []
    var selectedModuleID: String?
    var selectedLogSource: LogSource?
    var isTailing = false
    var searchText = ""

    private let detector = ToolDetector()

    var enabledModules: [any ToolModule] {
        modules.filter { enabledModuleIDs.contains($0.id) }
    }

    var selectedModule: (any ToolModule)? {
        guard let id = selectedModuleID else { return nil }
        return modules.first { $0.id == id }
    }

    var groupedModules: [(ToolCategory, [any ToolModule])] {
        let grouped = Dictionary(grouping: modules) { $0.category }
        return ToolCategory.allCases.compactMap { category in
            guard let tools = grouped[category], !tools.isEmpty else { return nil }
            return (category, tools)
        }
    }

    func detectTools() {
        let allModules = ModuleRegistry.allModules

        modules = allModules

        let overrides = UserDefaults.standard.dictionary(forKey: "moduleOverrides") as? [String: Bool] ?? [:]

        for module in allModules {
            if let override = overrides[module.id] {
                if override {
                    enabledModuleIDs.insert(module.id)
                }
            } else if module.isInstalled {
                enabledModuleIDs.insert(module.id)
            }
        }
    }

    func toggleModule(_ id: String) {
        if enabledModuleIDs.contains(id) {
            enabledModuleIDs.remove(id)
        } else {
            enabledModuleIDs.insert(id)
        }
        persistOverrides()
    }

    private func persistOverrides() {
        var overrides: [String: Bool] = [:]
        for module in modules {
            overrides[module.id] = enabledModuleIDs.contains(module.id)
        }
        UserDefaults.standard.set(overrides, forKey: "moduleOverrides")
    }
}
