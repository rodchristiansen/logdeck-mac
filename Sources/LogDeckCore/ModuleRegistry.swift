import Foundation

public enum ModuleRegistry {
    public static var allModules: [any ToolModule] {
        [
            MunkiModule(),
            BootstrapMateModule(),
            ReportMateModule(),
            OutsetModule(),
            IntuneModule(),
            ManagementScriptsModule(),
            CryptModule(),
            InstallApplicationsModule(),
            CommitsListenerModule()
        ]
    }

    public static func find(_ query: String) -> (any ToolModule)? {
        let lowered = query.lowercased()
        return allModules.first {
            $0.id == lowered || $0.name.lowercased() == lowered
        }
    }
}
