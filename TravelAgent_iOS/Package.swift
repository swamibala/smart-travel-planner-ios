// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TravelAgentApp",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .executable(name: "SmartTravelPlannerApp", targets: ["SmartTravelPlanner"])
    ],
    dependencies: [
        .package(url: "https://github.com/ml-explore/mlx-swift", branch: "main"),
        .package(url: "https://github.com/ml-explore/mlx-swift-lm", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "SmartTravelPlanner",
            dependencies: [
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "MLXLLM", package: "mlx-swift-lm")
            ],
            path: "SmartTravelPlanner",
            resources: [
                .copy("Resources/Llama_TravelAgent"),
                .process("Assets.xcassets")
            ]
        )
    ]
)
