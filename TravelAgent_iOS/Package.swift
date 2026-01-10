// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SmartTravelPlanner",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "SmartTravelPlanner", targets: ["SmartTravelPlanner"])
    ],
    dependencies: [
        .package(url: "https://github.com/ml-explore/mlx-swift", branch: "main"),
        .package(url: "https://github.com/ml-explore/mlx-swift-lm", branch: "main")
    ],
    targets: [
        .target(
            name: "SmartTravelPlanner",
            dependencies: [
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "MLXLLM", package: "mlx-swift-lm")
            ],
            path: "SmartTravelPlanner",
            resources: [
                .process("Resources"),
                .process("Assets.xcassets")
            ]
        )
    ]
)
