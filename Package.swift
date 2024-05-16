// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PatchouliJSON",
    products: [
        .library(
            name: "PatchouliJSON",
            targets: ["PatchouliJSON]),
    ],
    dependencies: [
        .package(url: "https://github.com/alexhunsley/patchouli-core", .upToNextMajor(from: "1.0.6"))
    ],
    targets: [
        .target(
            name: "PatchouliCore",
            dependencies: [.product(name: "PatchouliCore", package: "PatchouliCore")]
        ),
        .testTarget(
            name: "PatchouliJSONTests",
            dependencies: ["PatchouliJSON"]),
    ]
)
