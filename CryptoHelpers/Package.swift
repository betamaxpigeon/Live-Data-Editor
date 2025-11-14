// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "CryptoHelpers",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "CryptoHelpers",
            targets: ["CryptoHelpers"]
        ),
    ],
    targets: [
        .target(
            name: "CryptoHelpers",
            dependencies: [],
            path: "Sources/CryptoHelpers"
        ),
    ]
)
