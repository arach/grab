// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Grab",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "Grab",
            targets: ["Grab"]
        )
    ],
    dependencies: [
        // Add any external dependencies here
    ],
    targets: [
        .executableTarget(
            name: "Grab",
            dependencies: [],
            path: "Grab"
        )
    ]
)