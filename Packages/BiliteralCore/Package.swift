// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "BiliteralCore",
    defaultLocalization: "en",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "BiliteralCore", targets: ["BiliteralCore"])
    ],
    targets: [
        .target(name: "BiliteralCore"),
        .testTarget(name: "BiliteralCoreTests", dependencies: ["BiliteralCore"], resources: [.copy("Fixtures")])
    ]
)
