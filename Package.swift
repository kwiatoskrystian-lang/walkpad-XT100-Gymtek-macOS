// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "WalkMate",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .target(
            name: "WalkMateLib",
            path: "Sources/WalkMateLib"
        ),
        .executableTarget(
            name: "WalkMate",
            dependencies: ["WalkMateLib"],
            path: "Sources/WalkMate",
            exclude: ["Resources/Info.plist"]
        ),
        .executableTarget(
            name: "WalkMateTests",
            dependencies: ["WalkMateLib"],
            path: "Tests/WalkMateTests"
        )
    ]
)
