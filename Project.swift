import ProjectDescription

let project = Project(
    name: "PatchouliJSON",
    packages: [
        .package(url: "https://github.com/raymccrae/swift-jsonpatch.git", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        .target(
            name: "PatchouliJSON",
            destinations: .macOS,
            product: .staticLibrary,
            bundleId: "io.tuist.PatchouliJSON",
            sources: ["Sources/**"],
            dependencies:
            [
                .project(target: "PatchouliCore", path: "../PatchouliCore"),
//                .package(product: "swift-jsonpatch") // this defo is wrong.
                .package(product: "JSONPatch") //  <-- the right thing
            ]
        ),
        .target(
            name: "PatchouliJSONTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "io.tuist.PatchouliJSONTests",
            infoPlist: .default,
            sources: ["Tests/**"],
            resources: [],
            dependencies: [.target(name: "PatchouliJSON")]
        ),
    ]
)
