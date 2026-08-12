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
    dependencies: [
        .package(url: "https://github.com/aws-amplify/amplify-swift", exact: "2.58.3"),
        .package(url: "https://github.com/aws/aws-iot-device-sdk-swift", exact: "0.6.0")
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
                .product(name: "Amplify", package: "amplify-swift"),
                .product(name: "AWSAPIPlugin", package: "amplify-swift"),
                .product(name: "AWSCognitoAuthPlugin", package: "amplify-swift"),
                .product(name: "AWSPluginsCore", package: "amplify-swift"),
                .product(name: "AwsIotDeviceSdkSwift", package: "aws-iot-device-sdk-swift", condition: .when(platforms: [.iOS])),
            ],
            path: "Sources/SesameSDK",
            resources: [
                .process("DB/CHDeviceModel.xcdatamodeld")
            ]
        )
    ]
)
