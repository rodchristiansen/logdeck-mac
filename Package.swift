// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "LogDeck",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "LogDeckCore", targets: ["LogDeckCore"]),
        .executable(name: "LogDeck", targets: ["LogDeckApp"]),
        .executable(name: "logdeck", targets: ["LogDeckCLI"])
    ],
    targets: [
        .target(
            name: "LogDeckCore",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .executableTarget(
            name: "LogDeckApp",
            dependencies: ["LogDeckCore"],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .executableTarget(
            name: "LogDeckCLI",
            dependencies: ["LogDeckCore"],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "LogDeckTests",
            dependencies: ["LogDeckCore"],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
