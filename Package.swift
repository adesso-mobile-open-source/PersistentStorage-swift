// swift-tools-version: 6.2

//
//  Package.swift
//  PersistentStorage
//
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

import PackageDescription

let package = Package(
    name: "PersistentStorage",
    platforms: [.iOS(.v16), .macOS(.v13), .tvOS(.v18), .visionOS(.v1), .watchOS(.v11)],
    products: [
        .library(
            name: "PersistentStorage",
            targets: ["PersistentStorage"]
        )
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
        )
    ]
)
