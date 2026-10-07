// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "LogDeck",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "Core", targets: ["Core"]),
        .executable(name: "LogDeckApp", targets: ["GUI"]),
        .executable(name: "logdeck", targets: ["CLI"])
    ],
    targets: [
        .target(
            name: "Core",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .executableTarget(
            name: "GUI",
            dependencies: ["Core"],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .executableTarget(
            name: "CLI",
            dependencies: ["Core"],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "LogDeckTests",
            dependencies: ["Core"],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
