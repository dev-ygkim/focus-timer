import AppKit
import SwiftUI
import FocusTimerCore

struct TimerPopoverView: View {
    @ObservedObject var timerStore: PomodoroStore
    @ObservedObject var profileStore: ProfileStore

    private enum Panel {
        case timer
        case settings
        case profiles
    }

    @State private var panel = Panel.timer

    var body: some View {
        Group {
            switch panel {
            case .timer:
                timerPanel
            case .settings:
                SettingsView(timerStore: timerStore, onClose: {
                    panel = .timer
                })
            case .profiles:
                ProfileListView(timerStore: timerStore, profileStore: profileStore, onClose: {
                    panel = .timer
                })
            }
        }
    }

    private var timerPanel: some View {
        VStack(spacing: 16) {
            HStack {
                Label(timerStore.state.phase.displayName, systemImage: phaseSymbol)
                    .foregroundStyle(phaseColor)
                Spacer()
                Text("집중 \(timerStore.state.currentFocusCount) / \(timerStore.configuration.focusCount)")
                    .foregroundStyle(.secondary)
            }

            Text(timerStore.formattedTime)
                .font(.system(size: 52, weight: .light, design: .rounded))
                .monospacedDigit()

            ProgressView(value: elapsedSeconds, total: totalSeconds)
                .tint(phaseColor)

            Text(timerStore.nextStepText)
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack {
                Button(primaryActionTitle) {
                    if timerStore.state.isRunning {
                        timerStore.pause()
                    } else {
                        timerStore.start()
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("재설정") {
                    timerStore.reset()
                }
            }

            HStack {
                Button("설정") {
                    panel = .settings
                }
                Button("프로필") {
                    panel = .profiles
                }
            }

            Divider()

            Button("Focus Timer 종료", role: .destructive) {
                NSApplication.shared.terminate(nil)
            }
            .font(.footnote)
        }
        .padding(20)
        .frame(width: 350)
    }

    private var primaryActionTitle: String {
        if timerStore.state.isRunning {
            return "일시정지"
        }
        if timerStore.state.phase == .completed {
            return "새 타이머 시작"
        }
        return "시작"
    }

    private var phaseSymbol: String {
        switch timerStore.state.phase {
        case .focus:
            return "circle.fill"
        case .breakTime:
            return "cup.and.saucer.fill"
        case .completed:
            return "checkmark.circle.fill"
        }
    }

    private var phaseColor: Color {
        switch timerStore.state.phase {
        case .focus:
            return .teal
        case .breakTime:
            return .purple
        case .completed:
            return .secondary
        }
    }

    private var totalSeconds: Double {
        switch timerStore.state.phase {
        case .focus:
            return Double(timerStore.configuration.focusSeconds)
        case .breakTime:
            return Double(timerStore.configuration.breakSeconds)
        case .completed:
            return Double(timerStore.configuration.focusSeconds)
        }
    }

    private var elapsedSeconds: Double {
        max(0, totalSeconds - Double(timerStore.state.remainingSeconds))
    }
}
