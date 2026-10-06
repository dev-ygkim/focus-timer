import AppKit
import Foundation
import FocusTimerCore
@preconcurrency import UserNotifications

protocol AlertNotifying: AnyObject {
    func requestNotificationAuthorization()
    func send(_ alert: TimerAlert, settings: AlertSettings)
    func playSound(_ soundChoice: AlertSoundChoice, repeatCount: Int)
}

final class SilentAlertService: AlertNotifying {
    func requestNotificationAuthorization() {}
    func send(_ alert: TimerAlert, settings: AlertSettings) {}
    func playSound(_ soundChoice: AlertSoundChoice, repeatCount: Int) {}
}

final class AlertService: NSObject, AlertNotifying {
    private let center = UNUserNotificationCenter.current()
    private let transitionSound: NSSound?
    private var systemSounds: [AlertSoundChoice: NSSound] = [:]
    private var remainingRepeats = 0

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
            playSound(settings.soundChoice, repeatCount: settings.soundRepeatCount)
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

    func playSound(_ soundChoice: AlertSoundChoice, repeatCount: Int) {
        // 새 소리가 시작되면 이전 소리의 남은 반복은 취소합니다.
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        remainingRepeats = 0
        transitionSound?.stop()
        systemSounds.values.forEach { $0.stop() }

        guard let sound = sound(for: soundChoice) else {
            NSSound.beep()
            return
        }

        remainingRepeats = repeatCount - 1
        sound.delegate = self
        if !sound.play() {
            NSSound.beep()
        }
    }

    @objc private func replay(_ sound: NSSound) {
        sound.play()
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

extension AlertService: NSSoundDelegate {
    /// 소리가 끝까지 재생되면 잠깐 쉬고 남은 횟수만큼 다시 재생합니다. stop()으로 끊긴 경우(finished == false)는 반복하지 않습니다.
    func sound(_ sound: NSSound, didFinishPlaying finished: Bool) {
        guard finished, remainingRepeats > 0 else {
            return
        }
        remainingRepeats -= 1
        perform(#selector(replay(_:)), with: sound, afterDelay: 0.3)
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
