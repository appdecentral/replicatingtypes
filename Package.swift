// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "ReplicatingTypes",
    products: [
        .library(
            name: "ReplicatingTypes",
            targets: ["ReplicatingTypes"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "ReplicatingTypes",
            dependencies: []),
        .testTarget(
            name: "ReplicatingTypesTests",
            dependencies: ["ReplicatingTypes"]),
    ]
)
