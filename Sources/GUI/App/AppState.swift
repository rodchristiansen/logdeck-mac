import SwiftUI
import Core

@MainActor
@Observable
final class AppState {
    var modules: [any ToolModule] = []
    var enabledModuleIDs: Set<String> = []
    var selectedModuleID: String?
    var selectedLogSource: LogSource?
    /// What each module has on disk, from the last scan.
    var logs: [String: ModuleLogs] = [:]
    var isScanning = false

    private let detector = ToolDetector()

    var enabledModules: [any ToolModule] {
        modules.filter { enabledModuleIDs.contains($0.id) }
    }

    var selectedModule: (any ToolModule)? {
        guard let id = selectedModuleID else { return nil }
        return modules.first { $0.id == id }
    }

    /// Enabled modules by category, in registry order.
    var groupedModules: [(ToolCategory, [any ToolModule])] {
        let grouped = Dictionary(grouping: enabledModules) { $0.category }
        return ToolCategory.allCases.compactMap { category in
            guard let tools = grouped[category], !tools.isEmpty else { return nil }
            return (category, tools)
        }
    }

    var allGroupedModules: [(ToolCategory, [any ToolModule])] {
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
        enabledModuleIDs = []
        for module in allModules {
            if let override = overrides[module.id] {
                if override { enabledModuleIDs.insert(module.id) }
            } else if module.category == .managementTools || module.isInstalled {
                // The management tools are always listed, so a tool with no logs
                // says so instead of disappearing.
                enabledModuleIDs.insert(module.id)
            }
        }
        if selectedModuleID == nil {
            // The tool open last time, then the first installed one. A launch
            // argument (-selectedModule crypt) sets the same default.
            let remembered = UserDefaults.standard.string(forKey: "selectedModule")
            selectedModuleID = enabledModules.first { $0.id == remembered }?.id
                ?? enabledModules.first(where: \.isInstalled)?.id
                ?? enabledModules.first?.id
        }
    }

    /// Rescans every module's logs off the main thread.
    func refreshLogs() async {
        isScanning = true
        let current = modules
        let scanned = await Task.detached(priority: .userInitiated) {
            current.map { ModuleLogs(module: $0) }
        }.value
        logs = Dictionary(uniqueKeysWithValues: scanned.map { ($0.moduleID, $0) })
        isScanning = false
        selectNewestIfNeeded()
    }

    /// Opens the newest log of the selected tool, unless one of its logs is
    /// already open.
    func selectNewestIfNeeded() {
        guard let id = selectedModuleID, let moduleLogs = logs[id] else {
            selectedLogSource = nil
            return
        }
        let available = Set(moduleLogs.folders.flatMap { $0.sessions.map(\.source.id) } + moduleLogs.existingFiles.map(\.id))
        if let current = selectedLogSource, available.contains(current.id) { return }
        selectedLogSource = moduleLogs.newest
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
