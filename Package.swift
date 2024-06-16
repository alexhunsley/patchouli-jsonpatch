// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PatchouliJSON",
    products: [
        .library(
            name: "PatchouliJSON",
            targets: ["PatchouliJSON"]),
    ],
    dependencies: [
        .package(url: "https://github.com/alexhunsley/patchouli-core", .upToNextMajor(from: "0.9.1"))
    ],
    targets: [
        .target(
            name: "PatchouliJSON",
            dependencies: [.product(name: "PatchouliCore", package: "patchouli-core")]
        ),
        .testTarget(
            name: "PatchouliJSONTests",
            dependencies: ["PatchouliJSON"]),
    ]
)
