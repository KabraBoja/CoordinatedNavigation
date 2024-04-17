// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CoordinatedNavigation",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "CoordinatedNavigation", targets: ["CoordinatedNavigation"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CoordinatedNavigation",
            path: "src"
        ),
        .testTarget(
            name: "CoordinatedNavigationTests",
            dependencies: [
                "CoordinatedNavigation",
            ],
            path: "tests"
        )
    ]
)
