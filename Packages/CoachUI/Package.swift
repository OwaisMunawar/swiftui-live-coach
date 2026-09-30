// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "CoachUI",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "CoachUI", targets: ["CoachUI"]),
    ],
    dependencies: [
        .package(path: "../CoachCore"),
    ],
    targets: [
        .target(name: "CoachUI", dependencies: ["CoachCore"]),
    ]
)
