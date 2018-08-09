// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Rules",
    products: [
        .library(
            name: "Rules",
            targets: ["Rules"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Rules",
            dependencies: [])
    ]
)
