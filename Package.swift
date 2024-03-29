// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "contextserver",
    platforms: [
       .macOS(.v12)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
        //
        .package(url: "https://github.com/vapor/leaf.git", from: "4.0.0"),
        // 🐈
        .package(url: "https://github.com/OpenKitten/MongoKitten.git", from: "6.0.0"),

        .package(url: "https://github.com/swift-server/swift-service-lifecycle.git", from: "1.0.0-alpha"),

    ],
    targets: [
        
        .target(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Leaf", package: "leaf"),
                .product(name: "MongoKitten", package: "MongoKitten"),
                .product(name: "Lifecycle", package: "swift-service-lifecycle")
            ],
            swiftSettings: [
                // Enable better optimizations when building in Release configuration. Despite the use of
                // the `.unsafeFlags` construct required by SwiftPM, this flag is recommended for Release
                // builds. See <https://github.com/swift-server/guides/blob/main/docs/building.md#building-for-production> for details.
                
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release)),
            ]
        ),
        
        .executableTarget(name: "Run", dependencies: [.target(name: "App")]),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
