import AppKit
import Foundation
import SwiftUI
import FocusTimerCore
import FocusTimerUI

@main
struct FocusTimerReadmeSnapshot {
    @MainActor
    static func main() {
        guard (2...3).contains(CommandLine.arguments.count) else {
            fputs("Usage: FocusTimerReadmeSnapshot <output.png> [timer|settings|profiles]\n", stderr)
            exit(64)
        }

        let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
        let panel = CommandLine.arguments.count == 3 ? CommandLine.arguments[2] : "timer"
        let suiteName = "FocusTimerReadmeSnapshot.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        _ = NSApplication.shared
        let timerStore = PomodoroStore(defaults: defaults, usesSystemAlerts: false)
        let profileStore = ProfileStore(defaults: defaults)
        let rootView = view(for: panel, timerStore: timerStore, profileStore: profileStore)
        let hostingView = NSHostingView(rootView: rootView.preferredColorScheme(.dark))
        hostingView.appearance = NSAppearance(named: .darkAqua)
        hostingView.frame = NSRect(x: 0, y: 0, width: 390, height: 700)
        hostingView.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))

        let fittingSize = hostingView.fittingSize
        hostingView.frame.size = NSSize(width: max(360, fittingSize.width), height: max(1, fittingSize.height))
        hostingView.layoutSubtreeIfNeeded()

        let bounds = hostingView.bounds
        guard
            let bitmap = hostingView.bitmapImageRepForCachingDisplay(in: bounds),
            let data = {
                hostingView.cacheDisplay(in: bounds, to: bitmap)
                return bitmap.representation(using: .png, properties: [:])
            }()
        else {
            fputs("Could not render SwiftUI panel.\n", stderr)
            exit(1)
        }

        do {
            try FileManager.default.createDirectory(
                at: outputURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: outputURL)
            print("Created \(outputURL.path)")
        } catch {
            fputs("Could not write snapshot: \(error)\n", stderr)
            exit(1)
        }
    }

    @MainActor
    private static func view(
        for panel: String,
        timerStore: PomodoroStore,
        profileStore: ProfileStore
    ) -> AnyView {
        switch panel {
        case "timer":
            return AnyView(TimerPopoverView(timerStore: timerStore, profileStore: profileStore, isPinned: .constant(false)))
        case "settings":
            return AnyView(SettingsView(timerStore: timerStore, onClose: {}))
        case "profiles":
            _ = profileStore.save(name: "딥 워크", configuration: .standard)
            _ = profileStore.save(
                name: "글쓰기",
                configuration: TimerConfiguration(focusMinutes: 25, breakMinutes: 5, focusCount: 4)!
            )
            return AnyView(ProfileListView(timerStore: timerStore, profileStore: profileStore, onClose: {}))
        default:
            fputs("Unknown panel: \(panel)\n", stderr)
            exit(64)
        }
    }
}
