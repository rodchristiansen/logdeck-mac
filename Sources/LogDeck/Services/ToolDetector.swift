import Foundation

struct ToolDetector: Sendable {
    func detect(_ module: any ToolModule) -> DetectionResult {
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

struct DetectionResult: Sendable {
    let moduleID: String
    let isInstalled: Bool
    let foundPaths: [String]
    let missingPaths: [String]
}
