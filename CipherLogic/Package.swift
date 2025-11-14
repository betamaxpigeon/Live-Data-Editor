// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "CipherLogic",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "CipherLogic",
            targets: ["CipherLogic"]
        ),
        .library(
            name: "Base64Logic",
            targets: ["Base64Logic"]
        ),
        .library(
            name: "AES256Logic",
            targets: ["AES256Logic"]
        ),
        .library(
            name: "XChaChaPolyLogic",
            targets: ["XChaChaPolyLogic"]
        ),
        .library(
            name: "RSALogic",
            targets: ["RSALogic"]
        ),
    ],
    targets: [
        .target(
            name: "CipherLogic",
            dependencies: [
                "AES256Logic",
                "XChaChaPolyLogic",
                "RSALogic",
                "Base64Logic"
            ],
        ),
        .target(
            name: "Base64Logic"
        ),
        .target(
            name: "AES256Logic"
        ),
        .target(
            name: "XChaChaPolyLogic"
        ),
        .target(
            name: "RSALogic"
        ),
    ]
)
