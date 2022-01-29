// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(

    name: "BXMediaBrowser",
    
    // Deployment targets for each supported platform
    
    platforms:
    [
		.macOS(.v12), 	// TODO: We need to go back as far as Catalina
		.iOS(.v13)		// First version of iOS that supported SwiftUI
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
    ],
    
	// Targets are the basic building blocks of a package. A target can define a module or a test suite.
	// Targets can depend on other targets in this package, and on products in packages this package depends on.

    targets:
    [
        .target(name:"BXMediaBrowser", dependencies:["BXSwiftUtils","BXSwiftUI"]),
        .testTarget(name:"BXMediaBrowserTests", dependencies:["BXMediaBrowser"]),
    ]
)
