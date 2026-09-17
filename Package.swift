// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Codence",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "Codence",
            targets: ["Codence"]
        )
    ],
    targets: [
        .executableTarget(
            name: "Codence",
            path: ".",
            exclude: [
                "AGENTS.md",
                "CODEX.md",
                "CHANGELOG.md",
                "Codence.xcodeproj",
                "LICENSE",
                "Package.swift",
                "README.md",
                "Resources/Assets.xcassets",
                "Resources/Info.plist",
                "docs",
                "Tests"
            ],
            resources: [
                .copy("Resources/Icons"),
                .copy("Resources/codence-icon.svg")
            ]
        ),
        .testTarget(
            name: "CodenceTests",
            dependencies: ["Codence"],
            path: "Tests"
        )
    ]
)
