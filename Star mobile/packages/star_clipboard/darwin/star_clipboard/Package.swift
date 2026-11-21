// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "star_clipboard",
    platforms: [
        .iOS("16.0"),
        .macOS("12.0")
    ],
    products: [
        .library(name: "star-clipboard", targets: ["star_clipboard"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "star_clipboard",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
