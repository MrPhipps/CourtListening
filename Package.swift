// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CourtListening",
    platforms: [
        // iOS 17 / macOS 14 baseline: required by the SwiftUI @Observable presentation layer.
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(name: "CourtListeningCore", targets: ["CourtListeningCore"]),
        .library(name: "CourtListening", targets: ["CourtListening"]),
        .library(name: "CourtListeningUI", targets: ["CourtListeningUI"]),
    ],
    targets: [
        .target(
            name: "CourtListeningCore",
            dependencies: []
        ),
        .target(
            name: "CourtListening",
            dependencies: ["CourtListeningCore"]
        ),
        .target(
            name: "CourtListeningUI",
            dependencies: ["CourtListening", "CourtListeningCore"]
        ),
        .testTarget(
            name: "CourtListeningCoreTests",
            dependencies: ["CourtListeningCore"],
            resources: [.copy("Fixtures")]
        ),
        .testTarget(
            name: "CourtListeningTests",
            dependencies: ["CourtListening"],
            resources: [.copy("Fixtures")]
        ),
        .testTarget(
            name: "CourtListeningUITests",
            dependencies: ["CourtListeningUI"]
        ),
    ]
)
