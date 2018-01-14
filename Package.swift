// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "calabash-launcher",
    products: [
        .executable(
            name: "Calabash Launcher",
            targets: ["calabash-launcher"]),
    ],
    dependencies: [
        .package(url: "https://github.com/q231950/commands.git", from: "0.1.0"),
    ],
    targets: [
        .target(
            name: "calabash-launcher",
            dependencies: ["CommandsCore"],
            path: ".")
    ]
)
