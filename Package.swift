// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "LogDeck",
    platforms: [
        .macOS(.v15)
    ],
    targets: [
        .executableTarget(
            name: "LogDeck",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "LogDeckTests",
            dependencies: ["LogDeck"],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
