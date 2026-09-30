import AppKit
import Foundation
import FocusTimerCore
@preconcurrency import UserNotifications

protocol AlertNotifying: AnyObject {
    func requestNotificationAuthorization()
    func send(_ alert: TimerAlert, settings: AlertSettings)
    func playTransitionSound()
}

final class SilentAlertService: AlertNotifying {
    func requestNotificationAuthorization() {}
    func send(_ alert: TimerAlert, settings: AlertSettings) {}
    func playTransitionSound() {}
}

final class AlertService: NSObject, AlertNotifying {
    private let center = UNUserNotificationCenter.current()
    private let transitionSound: NSSound?

    override init() {
        transitionSound = Self.loadTransitionSound()
        super.init()
        center.delegate = self
    }

    func requestNotificationAuthorization() {
        center.requestAuthorization(options: [.alert]) { _, _ in }
    }

    func send(_ alert: TimerAlert, settings: AlertSettings) {
        if settings.soundEnabled {
            playTransitionSound()
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

    func playTransitionSound() {
        guard let transitionSound else {
            NSSound.beep()
            return
        }

        transitionSound.stop()
        if !transitionSound.play() {
            NSSound.beep()
        }
    }

    private static func loadTransitionSound() -> NSSound? {
        guard let url = Bundle.main.url(forResource: "transition", withExtension: "wav") else {
            return nil
        }

        let sound = NSSound(contentsOf: url, byReference: false)
        sound?.volume = 1.0
        return sound
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
