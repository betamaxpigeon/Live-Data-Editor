// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SettingsModule",
    platforms: [
      .macOS(.v26)
    ],
    products: [
        .library(
            name: "Settings",
            targets: ["Settings"]
        ),
    ],
    targets: [
        .target(
            name: "Settings",
        ),

    ]
)
