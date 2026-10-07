import Foundation
import Testing
@testable import Core

@Suite("Tool modules")
struct ToolModuleTests {
    @Test("Every management tool reads its /Library/Managed <Bucket>/logs folder")
    func managedLogFolders() {
        let expected: [String: String] = [
            "bootstrapmate": "/Library/Managed Bootstrap/logs",
            "reportmate": "/Library/Managed Reports/logs",
            "munki": "/Library/Managed Installs/logs",
            "outset": "/Library/Managed State/logs",
            "crypt": "/Library/Managed Encryption/logs",
            "swiftdialog": "/Library/Managed Notifications/logs",
            "manageusers": "/Library/Managed Users/logs"
        ]
        for (id, folder) in expected {
            let module = ModuleRegistry.find(id)
            #expect(module?.category == .managementTools)
            #expect(module?.logDirectories.first?.path == folder, "\(id)")
        }
    }

    @Test("The GUI apps in /Applications/Utilities are detection paths")
    func guiAppDetection() {
        let apps = [
            "bootstrapmate": "Managed Bootstrap Install.app",
            "reportmate": "Managed Reports Runner.app",
            "outset": "Managed State Keeper.app",
            "crypt": "Managed Encryption Escrow.app",
            "swiftdialog": "Managed Notifications Dialog.app",
            "manageusers": "Managed Users Cleanup.app"
        ]
        for (id, app) in apps {
            #expect(ModuleRegistry.find(id)?.detectionPaths.contains("/Applications/Utilities/\(app)") == true, "\(id)")
        }
    }

    @Test("Tools are found by role as well as id")
    func findByRole() {
        #expect(ModuleRegistry.find("Encryption")?.id == "crypt")
        #expect(ModuleRegistry.find("installs")?.id == "munki")
    }

    @Test("Module and log IDs are unique")
    func uniqueIDs() {
        let modules = ModuleRegistry.allModules
        let ids = modules.map(\.id)
        #expect(Set(ids).count == ids.count)
        for module in modules {
            let logIDs = module.logDirectories.map(\.id) + module.logSources.map(\.id)
            #expect(Set(logIDs).count == logIDs.count, "\(module.name)")
        }
    }
}

@Suite("Line levels")
struct LineLevelTests {
    @Test("Log file form: [timestamp] LEVEL message")
    func logFileForm() {
        #expect(LineLevel.classify("[2026-10-07 19:24:26] ERROR Filevault: FileVault is not enabled") == .error)
        #expect(LineLevel.classify("[2026-10-07 19:24:26] WARN  Disk nearly full") == .warning)
        #expect(LineLevel.classify("[2026-10-07 19:24:26] DEBUG checking") == .debug)
        #expect(LineLevel.classify("[2026-10-07 19:24:14] INFO  ===== ManageUsers started =====") == .header)
        #expect(LineLevel.classify("[2026-10-07 19:23:43] INFO  Processing on-demand-privileged") == .info)
    }

    @Test("Console form: LEVEL: message")
    func consoleForm() {
        #expect(LineLevel.classify("ERROR: Failed to download package") == .error)
        #expect(LineLevel.classify("WARNING: Certificate expires soon") == .warning)
        #expect(LineLevel.classify("DEBUG: Checking manifest") == .debug)
    }

    @Test("Markers and Munki's embedded level words")
    func markersAndFallback() {
        #expect(LineLevel.classify("  ✓ Installed Firefox") == .success)
        #expect(LineLevel.classify("  [!] Skipped") == .warning)
        #expect(LineLevel.classify("Oct 07 2026 10:00:00 -0700 ERROR: Could not resolve host") == .error)
        #expect(LineLevel.classify("Oct 07 2026 10:00:00 -0700 WARNING: Item not in catalog") == .warning)
        #expect(LineLevel.classify("Oct 07 2026 10:00:00 -0700 ### Beginning managed software check ###") == .info)
        #expect(LineLevel.classify("Starting managed software check") == .info)
        #expect(LineLevel.classify("") == .info)
    }
}

@Suite("Log folder scanning")
struct LogDirectoryTests {
    private func makeTree(_ files: [String: String]) throws -> String {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("logdeck-\(UUID().uuidString)").path
        for (relative, contents) in files {
            let path = (root as NSString).appendingPathComponent(relative)
            try FileManager.default.createDirectory(
                atPath: (path as NSString).deletingLastPathComponent,
                withIntermediateDirectories: true
            )
            try contents.write(toFile: path, atomically: true, encoding: .utf8)
        }
        try FileManager.default.createDirectory(atPath: root, withIntermediateDirectories: true)
        return root
    }

    @Test("Run sessions list newest first, with same-second suffixes")
    func runSessions() throws {
        let root = try makeTree([
            "2026-10-06/235959/outset.log": "a",
            "2026-10-07/191450/outset.log": "b",
            "2026-10-07/191450_2/outset.log": "c",
            "2026-10-07/192343/outset.log": "d",
            "2026-10-07/192343/events.jsonl": "{}",
            "outset.log": "legacy"
        ])
        defer { try? FileManager.default.removeItem(atPath: root) }
        let directory = LogDirectory(id: "t", label: "t", paths: [root], sessionLogNames: ["outset.log"])
        #expect(directory.sessions().map(\.name).contains("outset.log"))
        let sessions = directory.sessions().filter { $0.name != "outset.log" }
        #expect(sessions.map(\.name) == ["2026-10-07-192343", "2026-10-07-191450_2", "2026-10-07-191450", "2026-10-06-235959"])
        #expect(sessions.allSatisfy { $0.path.hasSuffix("/outset.log") && $0.hasTime })
    }

    @Test("Munki's HHMM sessions open run.log")
    func munkiSessions() throws {
        let root = try makeTree([
            "2026-10-07/0042/run.log": "a",
            "2026-10-07/0042/install.log": "b",
            "2026-10-07/0142/run.log": "c",
            "ManagedSoftwareUpdate.log": "flat"
        ])
        defer { try? FileManager.default.removeItem(atPath: root) }
        let directory = LogDirectory(
            id: "m", label: "m", paths: [root],
            sessionLogNames: ["run.log", "install.log"], includesFlatFiles: false
        )
        let sessions = directory.sessions()
        #expect(sessions.map(\.name) == ["2026-10-07-0142", "2026-10-07-0042"])
        #expect(sessions.allSatisfy { $0.path.hasSuffix("/run.log") })
    }

    @Test("Day directories list the day's log before its generations")
    func dayDirectories() throws {
        let root = try makeTree([
            "2026-10-06/dialog.log": "a",
            "2026-10-07/dialog.log": "b",
            "2026-10-07/dialog.log.1": "c",
            "2026-10-07/events.jsonl": "{}"
        ])
        defer { try? FileManager.default.removeItem(atPath: root) }
        let directory = LogDirectory(id: "d", label: "d", paths: [root], sessionLogNames: ["dialog.log"])
        let sessions = directory.sessions()
        #expect(sessions.map(\.name) == ["2026-10-07", "2026-10-07 (dialog.log.1)", "2026-10-06"])
        #expect(sessions.allSatisfy { !$0.hasTime })
    }

    @Test("A pinned current log leads its daily rolls")
    func pinnedFlatLogs() throws {
        let root = try makeTree([
            "crypt-2026-10-05.log": "a",
            "crypt-2026-10-06.log": "b",
            "crypt.log": "c",
            "notes.txt": "skip"
        ])
        defer { try? FileManager.default.removeItem(atPath: root) }
        let old = Date(timeIntervalSince1970: 0)
        try FileManager.default.setAttributes(
            [.modificationDate: old],
            ofItemAtPath: (root as NSString).appendingPathComponent("crypt.log")
        )
        let directory = LogDirectory(id: "c", label: "c", paths: [root], pinnedName: "crypt.log")
        #expect(directory.sessions().map(\.name) == ["crypt.log", "crypt-2026-10-06.log", "crypt-2026-10-05.log"])
    }

    @Test("A missing folder reports missing and lists nothing")
    func missingFolder() {
        let directory = LogDirectory(id: "x", label: "x", paths: ["/nonexistent/logdeck/logs"])
        #expect(directory.status() == .missing)
        #expect(directory.sessions().isEmpty)
    }

    @Test("Stamps parse with and without seconds")
    func stamps() {
        #expect(LogStamp.parseSession("2026-10-07-191450") != nil)
        #expect(LogStamp.parseSession("2026-10-07-191450_2") == LogStamp.parseSession("2026-10-07-191450"))
        #expect(LogStamp.parseSession("2026-10-07-0042") != nil)
        #expect(LogStamp.embeddedDate(in: "crypt-2026-10-05.log")?.hasTime == false)
        #expect(LogStamp.embeddedDate(in: "2026-10-07-142530.log")?.hasTime == true)
        #expect(LogStamp.generation(of: "dialog.log.3") == 3)
        #expect(LogStamp.generation(of: "dialog.log") == 0)
    }
}

@Suite("Log source")
struct LogSourceTests {
    @Test("Tilde expansion in resolved path")
    func tildeExpansion() {
        let source = LogSource(id: "test", label: "Test", path: "~/Library/Logs/outset.log")
        #expect(!source.resolvedPath.contains("~"))
        #expect(source.resolvedPath.hasSuffix("/Library/Logs/outset.log"))
    }

    @Test("A fallback path is used when the primary is missing")
    func fallback() {
        let source = LogSource(id: "t", label: "t", path: "/nonexistent/a.log", fallbackPaths: ["/etc/hosts"])
        #expect(source.resolvedPath == "/etc/hosts")
    }

    @Test("Non-existent file reports no size")
    func noFileSize() {
        let source = LogSource(id: "test", label: "Test", path: "/nonexistent/path/test.log")
        #expect(source.fileSize == nil)
        #expect(source.modificationDate == nil)
        #expect(!source.exists)
    }
}
