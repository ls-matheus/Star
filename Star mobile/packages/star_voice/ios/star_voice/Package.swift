// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "star_voice",
    platforms: [
        .iOS("16.0")
    ],
    products: [
        .library(name: "star-voice", targets: ["star_voice"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(name: "flutter_webrtc", path: "../flutter_webrtc")
    ],
    targets: [
        .target(
            name: "star_voice",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "flutter-webrtc", package: "flutter_webrtc"),
                .product(name: "WebRTC", package: "flutter_webrtc")
            ]
        )
    ]
)
