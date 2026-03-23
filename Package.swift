// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "MacDirStat",
    platforms: [.macOS(.v26)],
    targets: [
        .target(
            name: "MacDirStatKit",
            path: "Sources/MacDirStatKit"
        ),
        .executableTarget(
            name: "MacDirStat",
            dependencies: ["MacDirStatKit"],
            path: "Sources/MacDirStat"
        ),
        .testTarget(
            name: "MacDirStatTests",
            dependencies: ["MacDirStatKit"],
            path: "Tests"
        ),
    ]
)
