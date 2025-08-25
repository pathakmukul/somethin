// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VoiceAgentApp",
    platforms: [
        .iOS(.v17)
    ],
    dependencies: [
        .package(url: "https://github.com/get-convex/convex-mobile", from: "0.1.0"),
        .package(url: "https://github.com/Vapi-AI/ios-sdk", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "VoiceAgentApp",
            dependencies: [
                .product(name: "ConvexMobile", package: "convex-mobile"),
                .product(name: "Vapi", package: "ios-sdk")
            ]
        )
    ]
)