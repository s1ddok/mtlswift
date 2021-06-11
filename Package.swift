// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "mtlswift",
    products: [
        .executable(name: "mtlswift",
                    targets: ["mtlswift"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser",
                 from: "0.0.4"),
        .package(url: "https://github.com/JohnSundell/Files",
                 from: "4.0.2")
    ],
    targets: [
        .target(name: "mtlswift",
                dependencies: ["ArgumentParser", "Files"])
    ]
)
