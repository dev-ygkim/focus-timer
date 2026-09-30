import SwiftUI
import FocusTimerCore
import FocusTimerUI

@main
struct FocusTimerApp: App {
    @StateObject private var timerStore: PomodoroStore
    @StateObject private var profileStore: ProfileStore

    init() {
        _timerStore = StateObject(wrappedValue: PomodoroStore())
        _profileStore = StateObject(wrappedValue: ProfileStore())
    }

    var body: some Scene {
        MenuBarExtra {
            TimerPopoverView(timerStore: timerStore, profileStore: profileStore)
                .preferredColorScheme(.dark)
        } label: {
            Text(timerStore.menuBarText)
                .monospacedDigit()
        }
        .menuBarExtraStyle(.window)
    }
}
