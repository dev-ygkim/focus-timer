import AppKit
import Foundation
import FocusTimerCore
@preconcurrency import UserNotifications

protocol AlertNotifying: AnyObject {
    func requestNotificationAuthorization()
    func send(_ alert: TimerAlert, settings: AlertSettings)
}

final class AlertService: NSObject, AlertNotifying {
    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self
    }

    func requestNotificationAuthorization() {
        center.requestAuthorization(options: [.alert]) { _, _ in }
    }

    func send(_ alert: TimerAlert, settings: AlertSettings) {
        if settings.soundEnabled {
            NSSound.beep()
        }

        guard settings.notificationsEnabled else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = alert.title
        content.body = alert.body

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        center.add(request) { _ in }
    }
}

extension AlertService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list])
    }
}
