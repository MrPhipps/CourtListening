// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CourtListening",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
    ],
    products: [
        .library(name: "CourtListeningCore", targets: ["CourtListeningCore"]),
        .library(name: "CourtListening", targets: ["CourtListening"]),
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
    ]
)
