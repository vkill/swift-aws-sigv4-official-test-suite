// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AwsSigv4OfficialTestSuite",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "AwsSigv4OfficialTestSuite",
            targets: ["AwsSigv4OfficialTestSuite"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
	.package(url: "https://github.com/stencilproject/Stencil.git", from: "0.11.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "AwsSigv4OfficialTestSuite",
            dependencies: ["Stencil"]),
        .target(
            name: "AwsSigv4OfficialTestSuiteRun",
            dependencies: ["AwsSigv4OfficialTestSuite"]),
        .testTarget(
            name: "AwsSigv4OfficialTestSuiteTests",
            dependencies: ["AwsSigv4OfficialTestSuite"]),
    ]
)
