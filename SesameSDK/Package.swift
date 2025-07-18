// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "SesameSDK",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(name: "SesameSDK", targets: ["SesameSDK"]),
        .library(name: "AESc", targets: ["AESc"])
    ],
    dependencies: [
        .package(url: "https://github.com/aws-amplify/aws-sdk-ios-spm", .upToNextMajor(from: "2.0.0"))
    ],
    targets: [
        .target(
            name: "AESc",
            path: "Sources/AESc",
            publicHeadersPath: "."
        ),
        .target(
            name: "SesameSDK",
            dependencies: [
                "AESc",
                .product(name: "AWSCore", package: "aws-sdk-ios-spm"),
                .product(name: "AWSAPIGateway", package: "aws-sdk-ios-spm"),
                .product(name: "AWSIoT", package: "aws-sdk-ios-spm")
            ],
            path: "Sources/SesameSDK",
            resources: [
                .process("DB/CHDeviceModel.xcdatamodeld")
            ]
        )
    ]
)
