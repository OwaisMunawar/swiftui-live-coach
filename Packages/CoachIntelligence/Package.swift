// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "CoachIntelligence",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "CoachIntelligence", targets: ["CoachIntelligence"]),
    ],
    dependencies: [
        .package(path: "../CoachCore"),
    ],
    targets: [
        .target(name: "CoachIntelligence", dependencies: ["CoachCore"]),
        .testTarget(name: "CoachIntelligenceTests", dependencies: ["CoachIntelligence"]),
    ]
)
