// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Calabash Launcher Core",
    products: [
        .library(
            name: "Calabash Launcher Core",
            targets: ["CalabashLauncherCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/q231950/commands.git", .exact("0.0.6")),
    ],
    targets: [
        .target(
            name: "CalabashLauncherCore",
            dependencies: ["CommandsCore"])
    //    ,
    //    path: ".",
    //    sources:["Core/Classes"])
    ]
)
