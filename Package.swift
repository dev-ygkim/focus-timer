// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "FocusTimer",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "FocusTimer", targets: ["FocusTimerApp"]),
        .executable(name: "FocusTimerTDDTests", targets: ["FocusTimerTDDTests"])
    ],
    targets: [
        .target(name: "FocusTimerCore", path: "Sources/FocusTimerCore"),
        .executableTarget(
            name: "FocusTimerApp",
            dependencies: ["FocusTimerCore"],
            path: "Sources/FocusTimerApp"
        ),
        .executableTarget(
            name: "FocusTimerTDDTests",
            dependencies: ["FocusTimerCore"],
            path: "TDDTests",
            exclude: ["install-overwrite.sh", "menu-panel-navigation.sh"]
        )
    ]
)
