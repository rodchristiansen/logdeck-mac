import Foundation

protocol ToolModule: Identifiable, Sendable {
    var id: String { get }
    var name: String { get }
    var icon: String { get }
    var category: ToolCategory { get }
    var detectionPaths: [String] { get }
    var logSources: [LogSource] { get }
    var supportPaths: [SupportPath] { get }
    var isInstalled: Bool { get }
}

extension ToolModule {
    var isInstalled: Bool {
        detectionPaths.contains { FileManager.default.fileExists(atPath: $0) }
    }
}

enum ToolCategory: String, CaseIterable, Sendable {
    case packageManagement = "Package Management"
    case bootstrap = "Bootstrap & Enrollment"
    case reporting = "Reporting"
    case scripting = "Scripting & Automation"
    case mdm = "MDM & Endpoint"
    case security = "Security"
    case other = "Other"
}
