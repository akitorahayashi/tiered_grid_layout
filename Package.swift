// swift-tools-version: 5.9
// The swift-tools-version は、このパッケージのビルドに必要な Swift の最小バージョンを宣言

import PackageDescription

let package = Package(
    name: "TieredGridLayout",
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
        // 後でテストを追加する場合は、ここで定義
        .testTarget(
            name: "TieredGridLayoutTests",
            dependencies: ["TieredGridLayout"]
        ),
    ]
)
