import Foundation

public struct ToolDetector: Sendable {
    public init() {}

    public func detect(_ module: any ToolModule) -> DetectionResult {
        let foundPaths = module.detectionPaths.filter {
            FileManager.default.fileExists(atPath: ($0 as NSString).expandingTildeInPath)
        }
        return DetectionResult(
            moduleID: module.id,
            isInstalled: !foundPaths.isEmpty,
            foundPaths: foundPaths,
            missingPaths: module.detectionPaths.filter { !foundPaths.contains($0) }
        )
    }
}

public struct DetectionResult: Sendable {
    public let moduleID: String
    public let isInstalled: Bool
    public let foundPaths: [String]
    public let missingPaths: [String]
}
