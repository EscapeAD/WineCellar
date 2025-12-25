// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WineCellar",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "WineCellar",
            targets: ["WineCellar"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "WineCellar",
            path: "Sources/WineCellar",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "WineCellarTests",
            dependencies: ["WineCellar"],
            path: "Tests/WineCellarTests"
        ),
    ]
)

