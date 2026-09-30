import SwiftUI
import FocusTimerCore

@main
struct FocusTimerApp: App {
    @StateObject private var timerStore: PomodoroStore
    @StateObject private var profileStore: ProfileStore

    init() {
        let alertService = AlertService()
        _timerStore = StateObject(wrappedValue: PomodoroStore(alertService: alertService))
        _profileStore = StateObject(wrappedValue: ProfileStore())
    }

    var body: some Scene {
        MenuBarExtra {
            TimerPopoverView(timerStore: timerStore, profileStore: profileStore)
        } label: {
            Text(timerStore.menuBarText)
                .monospacedDigit()
        }
        .menuBarExtraStyle(.window)
    }
}
