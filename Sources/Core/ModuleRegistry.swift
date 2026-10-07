import Foundation

public enum ModuleRegistry {
    /// The management tools in suite order (Bootstrap, Reports, Installs,
    /// State, Encryption, Notifications, Users, Utilities), then MDM and local
    /// scripts.
    public static var allModules: [any ToolModule] {
        [
            BootstrapMateModule(),
            ReportMateModule(),
            MunkiModule(),
            OutsetModule(),
            CryptModule(),
            SwiftDialogModule(),
            ManageUsersModule(),
            UtilitiesModule(),
            IntuneModule(),
            ManagementScriptsModule()
        ]
    }

    public static func find(_ query: String) -> (any ToolModule)? {
        let lowered = query.lowercased()
        return allModules.first {
            $0.id == lowered || $0.name.lowercased() == lowered || $0.role.lowercased() == lowered
        }
    }
}
