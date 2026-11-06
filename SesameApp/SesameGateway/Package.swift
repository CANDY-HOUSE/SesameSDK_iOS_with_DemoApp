// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SesameGateway",
    platforms: [
        .iOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(name: "SesameGateway", targets: ["SesameGateway"])
    ],
    dependencies: [
        .package(url: "https://github.com/aws-amplify/amplify-swift", exact: "2.58.3")
    ],
    targets: [
        .target(
            name: "SesameGateway",
            dependencies: [
                .product(name: "Amplify", package: "amplify-swift"),
                .product(name: "AWSCognitoAuthPlugin", package: "amplify-swift"),
                .product(name: "AWSAPIPlugin", package: "amplify-swift")
            ]
        )
    ]
)
