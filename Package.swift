// swift-tools-version:5.6
// swiftformat:disable all

import PackageDescription

let package = Package(
    name: "SwiftFormatPlugin",
    platforms: [.iOS(.v13), .macOS(.v10_15)],
    products: [
        .plugin(name: "SwiftFormatPlugin", targets: ["SwiftFormatPlugin"])
    ],
    dependencies: [
//        .package(url: "https://github.com/nicklockwood/SwiftFormat.git", .upToNextMajor(from: "0.50.7"))
//        .package(url: "https://github.com/krzysztofzablocki/Sourcery.git", .upToNextMajor(from: "1.9.2"))
    ],
    targets: [
        .target(name: "TestTarget",
                dependencies: [
                ],
                path: "TestSource",
                plugins: [
                    "SwiftFormatPlugin"
                ]
               ),
        .plugin(
            name: "SwiftFormatPlugin",
            capability: .buildTool(),
            dependencies: [
                "swiftformat"
            ],
            path: "Source"
        ),
        .binaryTarget(
            name: "swiftformat",
            url: "https://github.com/nicklockwood/SwiftFormat/releases/download/0.50.7/swiftformat.artifactbundle.zip",
            checksum: "bb98990260e4c84791fde11f019d76d15e79846bd637633a3a026fd5c0fbd0db"
        )
    ]
)
