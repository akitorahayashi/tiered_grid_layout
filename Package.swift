// swift-tools-version: 5.9
// The swift-tools-version は、このパッケージのビルドに必要な Swift の最小バージョンを宣言

import PackageDescription

let package = Package(
    name: "tiered-grid-layout",
    platforms: [
        .iOS(.v16),
    ],
    products: [
        .library(
            name: "TieredGridLayout",
            targets: ["TieredGridLayout"]
        ),
    ],
    targets: [
        .target(
            name: "TieredGridLayout",
            path: "TieredGridLayout",
            exclude: [
                "Info.plist",
            ]
        ),
        .testTarget(
            name: "TieredGridLayoutTests",
            dependencies: ["TieredGridLayout"]
        ),
    ]
)
