// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Zone5",
	platforms: [
		.iOS(.v13),
		.macOS(.v10_15),
	],
    products: [
        .library(
			name: "Zone5",
			targets: [
				"Zone5"
			]
		),
    ],
    targets: [
        .target(
			name: "Zone5",
			path: "Zone5",
			exclude: [
				"Info.plist",
				"Zone5.h",
			]
		),
		.testTarget(
			name: "Zone5Tests",
			dependencies: ["Zone5"],
			path: "Zone5Tests",
			exclude: [
				"Info.plist"
			]
		),
    ]
)
