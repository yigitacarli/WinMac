// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WinMac",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "WinMac",
            targets: ["WinMac"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "WinMac",
            dependencies: [],
            path: "Sources"
        )
    ]
)
