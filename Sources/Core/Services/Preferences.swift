import Foundation

/// The app's preferences domain, and the move of settings from earlier domains.
public enum Preferences {
    /// The bundle identifier, and so the domain UserDefaults.standard reads.
    public static let domain = "com.github.rodchristiansen.logdeck"

    /// Domains earlier builds used, newest first.
    public static let legacyDomains = ["com.github.logdeck", "ca.ecuad.macadmin.LogDeck"]

    /// The keys the app stores.
    public static let keys = ["moduleOverrides", "selectedModule"]

    /// Copies each key the target does not yet have from the first legacy domain
    /// that holds it. A key already set in the target is never overwritten, so this
    /// is safe to run on every launch. The legacy domains are left as they are, so
    /// an older build run afterwards still finds its settings.
    @discardableResult
    public static func migrate(
        into target: UserDefaults,
        from legacy: [UserDefaults],
        keys: [String] = Preferences.keys
    ) -> [String] {
        var moved: [String] = []
        for key in keys where target.object(forKey: key) == nil {
            guard let value = legacy.lazy.compactMap({ $0.object(forKey: key) }).first else { continue }
            target.set(value, forKey: key)
            moved.append(key)
        }
        return moved
    }

    /// Moves settings from the earlier domains into UserDefaults.standard.
    public static func migrateStandard() {
        let legacy = legacyDomains
            .filter { $0 != Bundle.main.bundleIdentifier }
            .compactMap { UserDefaults(suiteName: $0) }
        migrate(into: .standard, from: legacy)
    }
}
