// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "BitcoinUhr",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "BitcoinUhr", path: "Sources/BitcoinUhr")
    ]
)
