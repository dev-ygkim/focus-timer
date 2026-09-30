import Darwin
import Foundation
import FocusTimerCore

struct TestFailure: Error, CustomStringConvertible {
    let description: String
}

@main
struct FocusTimerTDDTests {
    static func main() {
        let tests: [(String, () throws -> Void)] = [
            ("initial state starts ready for first focus", testInitialStateStartsReadyForFirstFocusSession),
            ("non-final focus starts break and emits alert", testFinishingNonFinalFocusStartsBreakAndEmitsFocusEndedAlert),
            ("break starts next focus and emits alert", testFinishingBreakStartsNextFocusAndEmitsBreakEndedAlert),
            ("final focus completes without final break", testFinishingFinalFocusCompletesWithoutStartingFinalBreak),
            ("paused timer does not advance", testPausedTimerDoesNotAdvanceOrEmitAlert),
            ("profile starts a new first focus session", testProfileStartsNewFirstFocusSessionImmediately),
            ("configuration rejects non-positive values", testConfigurationRejectsZeroOrNegativeValues),
            ("focus alert copy", testFocusEndedAlertDescribesStartingBreak),
            ("break alert copy", testBreakEndedAlertDescribesNextFocusSession),
            ("completion alert copy", testCompletionAlertDescribesFinishedFocusSessions),
            ("profile save trims name and persists", testSaveTrimsNameAndPersistsProfile),
            ("profile save rejects blank name", testSaveRejectsBlankName),
            ("profile save rejects duplicate name", testSaveRejectsNamesThatOnlyDifferByCaseOrWhitespace),
            ("profile store rejects eleventh profile", testStoreRejectsEleventhProfileWithoutChangingExistingProfiles),
            ("profile delete frees a slot", testDeleteRemovesOnlySelectedProfileAndFreesSlot)
        ]

        var failures = 0
        for (name, test) in tests {
            do {
                try test()
                print("PASS: \(name)")
            } catch {
                failures += 1
                fputs("FAIL: \(name) — \(error)\n", stderr)
            }
        }

        if failures == 0 {
            print("\nAll \(tests.count) TDD tests passed.")
        } else {
            fputs("\n\(failures) of \(tests.count) TDD tests failed.\n", stderr)
            exit(1)
        }
    }

    private static func testInitialStateStartsReadyForFirstFocusSession() throws {
        let configuration = try makeConfiguration(focus: 25, rest: 5, count: 4)
        let state = PomodoroState(configuration: configuration)

        try expectEqual(state.phase, .focus)
        try expectEqual(state.currentFocusCount, 1)
        try expectEqual(state.remainingSeconds, 25 * 60)
        try expectFalse(state.isRunning)
    }

    private static func testFinishingNonFinalFocusStartsBreakAndEmitsFocusEndedAlert() throws {
        let configuration = try makeConfiguration(focus: 25, rest: 5, count: 2)
        var state = PomodoroState(configuration: configuration)
        state.start()

        let alert = state.finishCurrentPhase()

        try expectEqual(state.phase, .breakTime)
        try expectEqual(state.currentFocusCount, 1)
        try expectEqual(state.remainingSeconds, 5 * 60)
        try expectTrue(state.isRunning)
        try expectEqual(alert, .focusEnded(breakMinutes: 5))
    }

    private static func testFinishingBreakStartsNextFocusAndEmitsBreakEndedAlert() throws {
        let configuration = try makeConfiguration(focus: 25, rest: 5, count: 2)
        var state = PomodoroState(configuration: configuration)
        state.start()
        _ = state.finishCurrentPhase()

        let alert = state.finishCurrentPhase()

        try expectEqual(state.phase, .focus)
        try expectEqual(state.currentFocusCount, 2)
        try expectEqual(state.remainingSeconds, 25 * 60)
        try expectTrue(state.isRunning)
        try expectEqual(alert, .breakEnded(nextFocusCount: 2, totalFocusCount: 2))
    }

    private static func testFinishingFinalFocusCompletesWithoutStartingFinalBreak() throws {
        let configuration = try makeConfiguration(focus: 25, rest: 5, count: 1)
        var state = PomodoroState(configuration: configuration)
        state.start()

        let alert = state.finishCurrentPhase()

        try expectEqual(state.phase, .completed)
        try expectEqual(state.currentFocusCount, 1)
        try expectEqual(state.remainingSeconds, 0)
        try expectFalse(state.isRunning)
        try expectEqual(alert, .timerCompleted(totalFocusCount: 1))
    }

    private static func testPausedTimerDoesNotAdvanceOrEmitAlert() throws {
        let configuration = try makeConfiguration(focus: 25, rest: 5, count: 2)
        var state = PomodoroState(configuration: configuration)
        state.start()
        state.pause()

        let alert = state.finishCurrentPhase()

        try expectNil(alert)
        try expectEqual(state.phase, .focus)
        try expectEqual(state.currentFocusCount, 1)
        try expectEqual(state.remainingSeconds, 25 * 60)
        try expectFalse(state.isRunning)
    }

    private static func testProfileStartsNewFirstFocusSessionImmediately() throws {
        let currentConfiguration = try makeConfiguration(focus: 25, rest: 5, count: 4)
        let profileConfiguration = try makeConfiguration(focus: 50, rest: 10, count: 3)
        let profile = TimerProfile(name: "Deep Work", configuration: profileConfiguration)
        var state = PomodoroState(configuration: currentConfiguration)
        state.start()

        state.start(profile: profile)

        try expectEqual(state.configuration, profileConfiguration)
        try expectEqual(state.phase, .focus)
        try expectEqual(state.currentFocusCount, 1)
        try expectEqual(state.remainingSeconds, 50 * 60)
        try expectTrue(state.isRunning)
    }

    private static func testConfigurationRejectsZeroOrNegativeValues() throws {
        try expectNil(TimerConfiguration(focusMinutes: 0, breakMinutes: 5, focusCount: 4))
        try expectNil(TimerConfiguration(focusMinutes: 25, breakMinutes: -1, focusCount: 4))
        try expectNil(TimerConfiguration(focusMinutes: 25, breakMinutes: 5, focusCount: 0))
    }

    private static func testFocusEndedAlertDescribesStartingBreak() throws {
        let alert = TimerAlert.focusEnded(breakMinutes: 5)

        try expectEqual(alert.title, "집중 완료")
        try expectEqual(alert.body, "휴식 5분을 시작합니다.")
    }

    private static func testBreakEndedAlertDescribesNextFocusSession() throws {
        let alert = TimerAlert.breakEnded(nextFocusCount: 2, totalFocusCount: 4)

        try expectEqual(alert.title, "휴식 완료")
        try expectEqual(alert.body, "집중 2 / 4를 시작합니다.")
    }

    private static func testCompletionAlertDescribesFinishedFocusSessions() throws {
        let alert = TimerAlert.timerCompleted(totalFocusCount: 4)

        try expectEqual(alert.title, "타이머 완료")
        try expectEqual(alert.body, "집중 4회를 완료했습니다.")
    }

    private static func testSaveTrimsNameAndPersistsProfile() throws {
        let environment = makeDefaults()
        defer { environment.defaults.removePersistentDomain(forName: environment.suiteName) }
        let store = ProfileStore(defaults: environment.defaults)
        let configuration = try makeConfiguration(focus: 25, rest: 5, count: 4)

        let profile = try store.save(name: "  Deep Work  ", configuration: configuration).get()

        try expectEqual(profile.name, "Deep Work")
        try expectEqual(store.profiles, [profile])

        let reloadedStore = ProfileStore(defaults: environment.defaults)
        try expectEqual(reloadedStore.profiles, [profile])
    }

    private static func testSaveRejectsBlankName() throws {
        let environment = makeDefaults()
        defer { environment.defaults.removePersistentDomain(forName: environment.suiteName) }
        let store = ProfileStore(defaults: environment.defaults)
        let result = store.save(name: "   ", configuration: try makeConfiguration(focus: 25, rest: 5, count: 4))

        try expectEqual(result, .failure(.emptyName))
        try expectTrue(store.profiles.isEmpty)
    }

    private static func testSaveRejectsNamesThatOnlyDifferByCaseOrWhitespace() throws {
        let environment = makeDefaults()
        defer { environment.defaults.removePersistentDomain(forName: environment.suiteName) }
        let store = ProfileStore(defaults: environment.defaults)
        let configuration = try makeConfiguration(focus: 25, rest: 5, count: 4)
        _ = try store.save(name: "Deep Work", configuration: configuration).get()

        let result = store.save(name: " deep work ", configuration: configuration)

        try expectEqual(result, .failure(.duplicateName))
        try expectEqual(store.profiles.count, 1)
    }

    private static func testStoreRejectsEleventhProfileWithoutChangingExistingProfiles() throws {
        let environment = makeDefaults()
        defer { environment.defaults.removePersistentDomain(forName: environment.suiteName) }
        let store = ProfileStore(defaults: environment.defaults)
        let configuration = try makeConfiguration(focus: 25, rest: 5, count: 4)

        for index in 1...ProfileStore.maximumProfiles {
            _ = try store.save(name: "Profile \(index)", configuration: configuration).get()
        }

        let result = store.save(name: "Overflow", configuration: configuration)

        try expectEqual(result, .failure(.maximumProfilesReached))
        try expectEqual(store.profiles.count, ProfileStore.maximumProfiles)
    }

    private static func testDeleteRemovesOnlySelectedProfileAndFreesSlot() throws {
        let environment = makeDefaults()
        defer { environment.defaults.removePersistentDomain(forName: environment.suiteName) }
        let store = ProfileStore(defaults: environment.defaults)
        let configuration = try makeConfiguration(focus: 25, rest: 5, count: 4)
        let first = try store.save(name: "First", configuration: configuration).get()
        let second = try store.save(name: "Second", configuration: configuration).get()

        store.delete(id: first.id)

        try expectEqual(store.profiles, [second])
        try expectTrue(store.canSaveAnotherProfile)
    }

    private static func makeConfiguration(focus: Int, rest: Int, count: Int) throws -> TimerConfiguration {
        guard let configuration = TimerConfiguration(focusMinutes: focus, breakMinutes: rest, focusCount: count) else {
            throw TestFailure(description: "Expected a valid timer configuration")
        }
        return configuration
    }

    private static func makeDefaults() -> (defaults: UserDefaults, suiteName: String) {
        let suiteName = "FocusTimerTDDTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return (defaults, suiteName)
    }

    private static func expectEqual<T: Equatable>(_ actual: T, _ expected: T, file: StaticString = #filePath, line: UInt = #line) throws {
        guard actual == expected else {
            throw TestFailure(description: "\(file):\(line) expected \(expected), got \(actual)")
        }
    }

    private static func expectTrue(_ value: Bool, file: StaticString = #filePath, line: UInt = #line) throws {
        guard value else {
            throw TestFailure(description: "\(file):\(line) expected true")
        }
    }

    private static func expectFalse(_ value: Bool, file: StaticString = #filePath, line: UInt = #line) throws {
        guard !value else {
            throw TestFailure(description: "\(file):\(line) expected false")
        }
    }

    private static func expectNil<T>(_ value: T?, file: StaticString = #filePath, line: UInt = #line) throws {
        guard value == nil else {
            throw TestFailure(description: "\(file):\(line) expected nil")
        }
    }
}
