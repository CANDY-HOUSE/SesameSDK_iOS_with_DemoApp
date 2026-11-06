// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SesameSDK",
    platforms: [
        .iOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(name: "SesameSDK", targets: ["SesameSDK"]),
        .library(name: "AESc", targets: ["AESc"])
    ],
    targets: [
        .target(
            name: "AESc",
            path: "Sources/AESc",
            publicHeadersPath: "."
        ),
        .target(
            name: "SesameSDK",
            dependencies: ["AESc"],
            path: "Sources/SesameSDK"
        )
    ]
)
