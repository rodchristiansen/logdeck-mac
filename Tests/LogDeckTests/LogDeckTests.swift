import Testing
@testable import Core

@Suite("Tool Module Detection")
struct ToolModuleTests {
    @Test("Munki module has correct detection paths")
    func munkiDetectionPaths() {
        let module = MunkiModule()
        #expect(module.id == "munki")
        #expect(module.detectionPaths.contains("/usr/local/munki/managedsoftwareupdate"))
        #expect(module.detectionPaths.contains("/Library/Managed Installs"))
        #expect(module.category == .packageManagement)
    }

    @Test("BootstrapMate module has correct detection paths")
    func bootstrapMateDetectionPaths() {
        let module = BootstrapMateModule()
        #expect(module.id == "bootstrapmate")
        #expect(module.detectionPaths.contains("/Applications/Utilities/BootstrapMate.app"))
        #expect(module.category == .bootstrap)
    }

    @Test("Outset module has correct log sources")
    func outsetLogSources() {
        let module = OutsetModule()
        #expect(module.logSources.count == 2)
        let rootLog = module.logSources.first { $0.id == "outset-root" }
        #expect(rootLog?.requiresPrivilege == true)
        let userLog = module.logSources.first { $0.id == "outset-user" }
        #expect(userLog?.requiresPrivilege == false)
    }

    @Test("Intune module uses rotation patterns for dated logs")
    func intuneRotation() {
        let module = IntuneModule()
        let daemonLogs = module.logSources.first { $0.id == "intune-ime-daemon" }
        #expect(daemonLogs?.rotationPattern != nil)
        #expect(daemonLogs?.requiresPrivilege == true)
    }

    @Test("Crypt module has security category")
    func cryptCategory() {
        let module = CryptModule()
        #expect(module.category == .security)
    }

    @Test("All modules have unique IDs")
    func uniqueModuleIDs() {
        let allModules: [any ToolModule] = [
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
        let ids = allModules.map(\.id)
        #expect(Set(ids).count == ids.count, "Module IDs must be unique")
    }

    @Test("All log sources have unique IDs within their module")
    func uniqueLogSourceIDs() {
        let allModules: [any ToolModule] = [
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
        for module in allModules {
            let ids = module.logSources.map(\.id)
            #expect(Set(ids).count == ids.count, "Log source IDs must be unique in \(module.name)")
        }
    }
}

@Suite("Log Entry Parsing")
struct LogEntryTests {
    @Test("Error severity detection")
    func errorDetection() {
        let entry = LogEntry(id: 0, line: "2026-03-13 ERROR: Failed to download package")
        #expect(entry.severity == .error)
    }

    @Test("Warning severity detection")
    func warningDetection() {
        let entry = LogEntry(id: 0, line: "WARNING: Certificate expires soon")
        #expect(entry.severity == .warning)
    }

    @Test("Debug severity detection")
    func debugDetection() {
        let entry = LogEntry(id: 0, line: "DEBUG: Checking manifest...")
        #expect(entry.severity == .debug)
    }

    @Test("Info severity is default")
    func infoDefault() {
        let entry = LogEntry(id: 0, line: "Starting managed software check")
        #expect(entry.severity == .info)
    }
}

@Suite("Log Source")
struct LogSourceTests {
    @Test("Tilde expansion in resolved path")
    func tildeExpansion() {
        let source = LogSource(id: "test", label: "Test", path: "~/Library/Logs/outset.log")
        #expect(!source.resolvedPath.contains("~"))
        #expect(source.resolvedPath.hasSuffix("/Library/Logs/outset.log"))
    }

    @Test("Non-existent file reports no size")
    func noFileSize() {
        let source = LogSource(id: "test", label: "Test", path: "/nonexistent/path/test.log")
        #expect(source.fileSize == nil)
        #expect(source.modificationDate == nil)
        #expect(!source.exists)
    }
}
