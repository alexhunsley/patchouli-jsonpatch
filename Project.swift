import ProjectDescription

let project = Project(
    name: "PatchouliJSON",
    packages: [
        .package(url: "https://github.com/raymccrae/swift-jsonpatch.git", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        .target(
            name: "PatchouliJSON",
//            destinations: .macOS,
            destinations: [.mac, .appleTv, .appleWatch, .appleVision, .iPad, .iPhone],
            product: .staticLibrary,
            bundleId: "io.tuist.PatchouliJSON",
            sources: ["Sources/**"],
            dependencies:
            [
                .project(target: "PatchouliCore", path: "../PatchouliCore"),
                .package(product: "JSONPatch")
            ]
        ),
        .target(
            name: "PatchouliJSONTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "io.tuist.PatchouliJSONTests",
            infoPlist: .default,
            sources: ["Tests/Sources/**"],
            resources: ["Tests/Resources/**"],
            dependencies: [.target(name: "PatchouliJSON")]
        ),
    ]
)

///// iPhone support
//case iPhone
//
///// iPad support
//case iPad
//
///// Native macOS support
//case mac
//
///// macOS support using iPad design
//case macWithiPadDesign
//
///// mac Catalyst support
//case macCatalyst
//
///// watchOS support
//case appleWatch
//
///// tvOS support
//case appleTv
//
///// visionOS support
//case appleVision
//
///// visionOS support using iPad design
//case appleVisionWithiPadDesign
