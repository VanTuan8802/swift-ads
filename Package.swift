// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-ads",
    defaultLocalization: "en",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "swift-ads",
            targets: ["swift-ads"]),
    ],
    dependencies: [
        .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git", from: "13.6.0"),
        .package(url: "https://github.com/airbnb/lottie-spm.git", from: "4.6.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", "11.0.0"..<"13.0.0"),
        .package(url: "https://github.com/adjust/ios_sdk.git", from: "5.0.0"),
        .package(url: "https://github.com/facebook/facebook-ios-sdk.git", from: "18.0.0")
    ],
    targets: [
        // Objective-C target exposing Google Ads Preview headers (PreloadDelegate, PreloadConfigurationV2, etc.)
        .target(
            name: "PreloadPreview",
            dependencies: [
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads"),
            ],
            path: "Sources/PreloadPreview",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include"),
            ]
        ),
        // Main swift-ads target
        .target(
            name: "swift-ads",
            dependencies: [
                "PreloadPreview",
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads"),
                .product(name: "Lottie", package: "lottie-spm"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "AdjustSdk", package: "ios_sdk"),
                .product(name: "FacebookCore", package: "facebook-ios-sdk"),
            ],
            resources: [
                .process("Animation")
            ]),
        .testTarget(
            name: "swift-adsTests",
            dependencies: ["swift-ads"]
        ),
    ]
)
