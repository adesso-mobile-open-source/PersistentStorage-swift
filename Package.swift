// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "PersistentStorage",
    platforms: [.iOS(.v16), .macOS(.v13), .tvOS(.v16), .visionOS(.v1), .watchOS(.v9)],
    products: [
        .library(
            name: "PersistentStorage",
            targets: ["PersistentStorage"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Matejkob/swift-spyable", from: "0.9.0")
    ],
    targets: [
        .target(
            name: "PersistentStorage",
            dependencies: [.product(name: "Spyable", package: "swift-spyable")]
        ),
        .testTarget(
            name: "PersistentStorageTests",
            dependencies: [
                "PersistentStorage",
                .product(name: "Spyable", package: "swift-spyable")
            ]
        ),
    ]
)
