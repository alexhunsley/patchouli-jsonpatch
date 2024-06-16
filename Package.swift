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
        .package(url: "https://github.com/alexhunsley/patchouli-core", .upToNextMajor(from: "0.9.1")),
        .package(url: "https://github.com/raymccrae/swift-jsonpatch.git", .upToNextMajor(from: "1.0.0"))
    ],

    ],
    targets: [
        .target(
            name: "PatchouliJSON",
            dependencies: [
                .product(name: "PatchouliCore", package: "patchouli-core"),
                .product(name: "JSONPatch", package: "swift-jsonpatch")
            ]
        ),
        .testTarget(
            name: "PatchouliJSONTests",
            dependencies: ["PatchouliJSON"]),
    ]
)
