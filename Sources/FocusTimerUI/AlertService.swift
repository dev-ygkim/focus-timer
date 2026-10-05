import AppKit
import Foundation
import FocusTimerCore
@preconcurrency import UserNotifications

protocol AlertNotifying: AnyObject {
    func requestNotificationAuthorization()
    func send(_ alert: TimerAlert, settings: AlertSettings)
    func playSound(_ soundChoice: AlertSoundChoice)
}

final class SilentAlertService: AlertNotifying {
    func requestNotificationAuthorization() {}
    func send(_ alert: TimerAlert, settings: AlertSettings) {}
    func playSound(_ soundChoice: AlertSoundChoice) {}
}

final class AlertService: NSObject, AlertNotifying {
    private let center = UNUserNotificationCenter.current()
    private let transitionSound: NSSound?
    private var systemSounds: [AlertSoundChoice: NSSound] = [:]

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
            playSound(settings.soundChoice)
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

    func playSound(_ soundChoice: AlertSoundChoice) {
        guard let sound = sound(for: soundChoice) else {
            NSSound.beep()
            return
        }

        transitionSound?.stop()
        systemSounds.values.forEach { $0.stop() }
        if !sound.play() {
            NSSound.beep()
        }
    }

    private func sound(for soundChoice: AlertSoundChoice) -> NSSound? {
        if soundChoice == .appDefault {
            return transitionSound
        }

        if let sound = systemSounds[soundChoice] {
            return sound
        }

        guard let fileName = soundChoice.systemSoundFileName else {
            return nil
        }

        let url = URL(fileURLWithPath: "/System/Library/Sounds", isDirectory: true)
            .appendingPathComponent(fileName)
        let sound = NSSound(contentsOf: url, byReference: false)
        sound?.volume = 1.0
        if let sound {
            systemSounds[soundChoice] = sound
        }
        return sound
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
