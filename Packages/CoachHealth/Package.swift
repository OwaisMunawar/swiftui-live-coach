// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "CoachHealth",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "CoachHealth", targets: ["CoachHealth"]),
    ],
    dependencies: [
        .package(path: "../CoachCore"),
    ],
    targets: [
        .target(name: "CoachHealth", dependencies: ["CoachCore"]),
        .testTarget(name: "CoachHealthTests", dependencies: ["CoachHealth"]),
    ]
)
