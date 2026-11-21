// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "star_voice",
    platforms: [
        .macOS("12.0")
    ],
    products: [
        .library(name: "star-voice", targets: ["star_voice"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "star_voice",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
