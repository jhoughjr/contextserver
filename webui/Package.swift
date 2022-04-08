// swift-tools-version:5.3
import PackageDescription
let package = Package(
    name: "webui",
    platforms: [.macOS("12")  ],
    products: [
        .executable(name: "webui", targets: ["webui"])
    ],
    dependencies: [
//        .package(name: "Tokamak",
//                 url: "https://github.com/TokamakUI/Tokamak",
//                 from: "0.9.1"),
        .package(
            url: "https://github.com/TokamakUI/Tokamak",
            .branch("main")
        )
    ],
    targets: [
        .target(
            name: "webui",
            dependencies: [
                .product(name: "TokamakShim", package: "Tokamak")
            ]),
        .testTarget(
            name: "webuiTests",
            dependencies: ["webui"]),
    ]
)
