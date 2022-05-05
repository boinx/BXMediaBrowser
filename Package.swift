// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(

    name: "BXMediaBrowser",
    defaultLocalization: "en",
    
    // Deployment targets for each supported platform
    
    platforms:
    [
		.macOS("10.15.2"), 	// First version that has reasonable SwiftUI support, NSCollectionViewDiffableDataSource
		.iOS("13.2")		// First version that has reasonable SwiftUI support
    ],
    
	// Products define the executables and libraries a package produces, and make them visible to other packages

    products:
    [
        .library(name:"BXMediaBrowser", targets:["BXMediaBrowser"]),
    ],
    
	// Dependencies declare other packages that this package depends on

    dependencies:
    [
        .package(url:"git@github.com:boinx/BXSwiftUtils.git", .branch("master")),
        .package(url:"git@github.com:boinx/BXSwiftUI.git", .branch("master")),
        .package(url:"https://github.com/p2/OAuth2.git", .upToNextMajor(from:"5.0.0")),
    ],
    
	// Targets are the basic building blocks of a package. A target can define a module or a test suite.
	// Targets can depend on other targets in this package, and on products in packages this package depends on.

    targets:
    [
        .target(name:"BXMediaBrowser", dependencies:["BXSwiftUtils","BXSwiftUI"]),
        .testTarget(name:"BXMediaBrowserTests", dependencies:["BXMediaBrowser"]),
    ]
)
