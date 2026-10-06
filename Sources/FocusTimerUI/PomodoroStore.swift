import Combine
import Foundation
import FocusTimerCore

@MainActor
public final class PomodoroStore: ObservableObject {
    @Published public private(set) var state: PomodoroState
    @Published public private(set) var alertSettings: AlertSettings

    private let defaults: UserDefaults
    private let alertService: any AlertNotifying
    private var ticker: Timer?
    private var endDate: Date?

    private enum StorageKey {
        static let configuration = "FocusTimer.configuration"
        static let alertSettings = "FocusTimer.alertSettings"
    }

    public init(defaults: UserDefaults = .standard, usesSystemAlerts: Bool = true) {
        self.defaults = defaults
        alertService = usesSystemAlerts ? AlertService() : SilentAlertService()

        let configuration = Self.decode(TimerConfiguration.self, from: defaults, key: StorageKey.configuration) ?? .standard
        state = PomodoroState(configuration: configuration)
        alertSettings = Self.decode(AlertSettings.self, from: defaults, key: StorageKey.alertSettings) ?? AlertSettings()
    }

    var configuration: TimerConfiguration {
        state.configuration
    }

    var formattedTime: String {
        let minutes = state.remainingSeconds / 60
        let seconds = state.remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    public var menuBarText: String {
        state.phase == .completed ? "완료" : "\(state.phase.displayName) \(formattedTime)"
    }

    var nextStepText: String {
        switch state.phase {
        case .focus:
            if state.currentFocusCount == state.configuration.focusCount {
                return "다음 단계: 완료"
            }
            return "다음 단계: 휴식 \(state.configuration.breakMinutes)분"
        case .breakTime:
            return "다음 단계: 집중 \(state.currentFocusCount + 1) / \(state.configuration.focusCount)"
        case .completed:
            return "모든 집중을 완료했습니다."
        }
    }

    func start() {
        if state.phase == .completed {
            state.reset()
        }

        state.start()
        guard state.isRunning else {
            return
        }

        if alertSettings.notificationsEnabled {
            alertService.requestNotificationAuthorization()
        }
        beginCountdown()
    }

    func pause() {
        refreshCountdown()
        invalidateTicker()
        state.pause()
    }

    func reset() {
        invalidateTicker()
        state.reset()
    }

    func apply(configuration: TimerConfiguration, alertSettings: AlertSettings) {
        guard !state.isRunning else {
            return
        }

        state.apply(configuration: configuration)
        self.alertSettings = alertSettings
        persist(configuration: configuration, alertSettings: alertSettings)

        if alertSettings.notificationsEnabled {
            alertService.requestNotificationAuthorization()
        }
    }

    func start(profile: TimerProfile) {
        invalidateTicker()
        state.start(profile: profile)
        persist(configuration: profile.configuration, alertSettings: alertSettings)

        if alertSettings.notificationsEnabled {
            alertService.requestNotificationAuthorization()
        }
        beginCountdown()
    }

    func previewSound(_ soundChoice: AlertSoundChoice, repeatCount: Int) {
        alertService.playSound(soundChoice, repeatCount: repeatCount)
    }

    private func beginCountdown() {
        invalidateTicker()
        endDate = Date().addingTimeInterval(TimeInterval(state.remainingSeconds))

        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshCountdown()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    private func refreshCountdown() {
        guard state.isRunning, let endDate else {
            return
        }

        let remainingSeconds = max(0, Int(ceil(endDate.timeIntervalSinceNow)))
        state.updateRemainingSeconds(remainingSeconds)

        guard remainingSeconds == 0 else {
            return
        }

        let alert = state.finishCurrentPhase()
        invalidateTicker()

        if let alert {
            alertService.send(alert, settings: alertSettings)
        }

        if state.isRunning {
            beginCountdown()
        }
    }

    private func invalidateTicker() {
        ticker?.invalidate()
        ticker = nil
        endDate = nil
    }

    private func persist(configuration: TimerConfiguration, alertSettings: AlertSettings) {
        if let configurationData = try? JSONEncoder().encode(configuration) {
            defaults.set(configurationData, forKey: StorageKey.configuration)
        }
        if let alertSettingsData = try? JSONEncoder().encode(alertSettings) {
            defaults.set(alertSettingsData, forKey: StorageKey.alertSettings)
        }
    }

    private static func decode<Value: Decodable>(_ type: Value.Type, from defaults: UserDefaults, key: String) -> Value? {
        guard let data = defaults.data(forKey: key) else {
            return nil
        }
        return try? JSONDecoder().decode(Value.self, from: data)
    }
}
