import AppKit
import SwiftUI
import FocusTimerCore
import FocusTimerUI

@main
struct FocusTimerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // 메뉴바 아이콘과 창은 MenuBarController가 관리하므로 빈 Settings 장면만 둡니다.
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBar: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBar = MenuBarController(timerStore: PomodoroStore(), profileStore: ProfileStore())
    }
}
