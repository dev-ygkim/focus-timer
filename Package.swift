// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "FocusTimer",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "FocusTimer", targets: ["FocusTimerApp"]),
        .executable(name: "FocusTimerTDDTests", targets: ["FocusTimerTDDTests"]),
        .executable(name: "FocusTimerReadmeSnapshot", targets: ["FocusTimerReadmeSnapshot"])
    ],
    targets: [
        .target(name: "FocusTimerCore", path: "Sources/FocusTimerCore"),
        .target(
            name: "FocusTimerUI",
            dependencies: ["FocusTimerCore"],
            path: "Sources/FocusTimerUI"
        ),
        .executableTarget(
            name: "FocusTimerApp",
            dependencies: ["FocusTimerCore", "FocusTimerUI"],
            path: "Sources/FocusTimerApp"
        ),
        .executableTarget(
            name: "FocusTimerReadmeSnapshot",
            dependencies: ["FocusTimerCore", "FocusTimerUI"],
            path: "Tools/FocusTimerReadmeSnapshot"
        ),
        .executableTarget(
            name: "FocusTimerTDDTests",
            dependencies: ["FocusTimerCore"],
            path: "TDDTests",
            exclude: [
                "install-overwrite.sh",
                "menu-panel-navigation.sh",
                "transition-sound.sh",
                "custom-menu-ui-style.sh",
                "readme-snapshot.sh",
                "app-version.sh",
                "always-on-top.sh",
                "app-signature.sh"
            ]
        )
    ]
)
