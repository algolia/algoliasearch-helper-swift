// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "InstantSearchCore",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "InstantSearchCore",
            targets: ["InstantSearchCore"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
      .package(url:"https://github.com/algolia/algoliasearch-client-swift", .branch("release/7.0.2"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "InstantSearchCore",
            dependencies: ["InstantSearchClient"],
	    path: "./Sources"),
        .testTarget(
            name: "instantsearch-core-swiftTests",
            dependencies: ["InstantSearchCore"],
            path: "./Tests/Sources"),
    ]
)