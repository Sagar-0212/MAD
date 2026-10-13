// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "CareCircle",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "CareCircle",
            targets: ["CareCircle"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", exact: "10.19.0")
    ],
    targets: [
        .target(
            name: "CareCircle",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
            ],
            path: "CareCircle"
        )
    ]
)
