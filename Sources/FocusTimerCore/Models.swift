import Foundation

public struct TimerConfiguration: Codable, Equatable, Sendable {
    public let focusMinutes: Int
    public let breakMinutes: Int
    public let focusCount: Int

    public init?(focusMinutes: Int, breakMinutes: Int, focusCount: Int) {
        guard focusMinutes > 0, breakMinutes > 0, focusCount > 0 else {
            return nil
        }

        self.focusMinutes = focusMinutes
        self.breakMinutes = breakMinutes
        self.focusCount = focusCount
    }

    public static let standard = TimerConfiguration(focusMinutes: 25, breakMinutes: 5, focusCount: 4)!

    public var focusSeconds: Int {
        focusMinutes * 60
    }

    public var breakSeconds: Int {
        breakMinutes * 60
    }
}

public struct AlertSettings: Codable, Equatable {
    public var soundEnabled: Bool
    public var notificationsEnabled: Bool

    public init(soundEnabled: Bool = true, notificationsEnabled: Bool = true) {
        self.soundEnabled = soundEnabled
        self.notificationsEnabled = notificationsEnabled
    }
}

public struct TimerProfile: Codable, Equatable, Identifiable {
    public let id: UUID
    public let name: String
    public let configuration: TimerConfiguration

    public init(id: UUID = UUID(), name: String, configuration: TimerConfiguration) {
        self.id = id
        self.name = name
        self.configuration = configuration
    }
}

public enum TimerPhase: String, Codable, Equatable {
    case focus
    case breakTime
    case completed

    public var displayName: String {
        switch self {
        case .focus:
            return "집중"
        case .breakTime:
            return "휴식"
        case .completed:
            return "완료"
        }
    }
}

public enum TimerAlert: Equatable {
    case focusEnded(breakMinutes: Int)
    case breakEnded(nextFocusCount: Int, totalFocusCount: Int)
    case timerCompleted(totalFocusCount: Int)

    public var title: String {
        switch self {
        case .focusEnded:
            return "집중 완료"
        case .breakEnded:
            return "휴식 완료"
        case .timerCompleted:
            return "타이머 완료"
        }
    }

    public var body: String {
        switch self {
        case let .focusEnded(breakMinutes):
            return "휴식 \(breakMinutes)분을 시작합니다."
        case let .breakEnded(nextFocusCount, totalFocusCount):
            return "집중 \(nextFocusCount) / \(totalFocusCount)를 시작합니다."
        case let .timerCompleted(totalFocusCount):
            return "집중 \(totalFocusCount)회를 완료했습니다."
        }
    }
}

public struct PomodoroState: Equatable {
    public private(set) var configuration: TimerConfiguration
    public private(set) var phase: TimerPhase
    public private(set) var currentFocusCount: Int
    public private(set) var remainingSeconds: Int
    public private(set) var isRunning: Bool

    public init(configuration: TimerConfiguration) {
        self.configuration = configuration
        phase = .focus
        currentFocusCount = 1
        remainingSeconds = configuration.focusSeconds
        isRunning = false
    }

    public mutating func start() {
        guard phase != .completed else {
            return
        }
        isRunning = true
    }

    public mutating func pause() {
        isRunning = false
    }

    public mutating func reset() {
        phase = .focus
        currentFocusCount = 1
        remainingSeconds = configuration.focusSeconds
        isRunning = false
    }

    public mutating func apply(configuration: TimerConfiguration) {
        guard !isRunning else {
            return
        }
        self.configuration = configuration
        reset()
    }

    public mutating func start(profile: TimerProfile) {
        configuration = profile.configuration
        reset()
        isRunning = true
    }

    public mutating func updateRemainingSeconds(_ seconds: Int) {
        guard isRunning else {
            return
        }
        remainingSeconds = max(0, seconds)
    }

    public mutating func finishCurrentPhase() -> TimerAlert? {
        guard isRunning else {
            return nil
        }

        switch phase {
        case .focus:
            if currentFocusCount == configuration.focusCount {
                phase = .completed
                remainingSeconds = 0
                isRunning = false
                return .timerCompleted(totalFocusCount: configuration.focusCount)
            }

            phase = .breakTime
            remainingSeconds = configuration.breakSeconds
            return .focusEnded(breakMinutes: configuration.breakMinutes)

        case .breakTime:
            currentFocusCount += 1
            phase = .focus
            remainingSeconds = configuration.focusSeconds
            return .breakEnded(nextFocusCount: currentFocusCount, totalFocusCount: configuration.focusCount)

        case .completed:
            return nil
        }
    }
}
