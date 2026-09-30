// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "CoachCore",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "CoachCore", targets: ["CoachCore"]),
    ],
    targets: [
        .target(name: "CoachCore"),
        .testTarget(name: "CoachCoreTests", dependencies: ["CoachCore"]),
    ]
)
