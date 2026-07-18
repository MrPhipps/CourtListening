// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CourtListening",
    platforms: [
        // OS 26 baseline (Xcode 27 / Swift 6 toolchain).
        .macOS("26.0"),
        .iOS("26.0"),
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
