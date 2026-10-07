import AppKit
import SwiftUI
import FocusTimerCore

public struct TimerPopoverView: View {
    @ObservedObject var timerStore: PomodoroStore
    @ObservedObject var profileStore: ProfileStore
    @Binding var isPinned: Bool
    @Binding var pinnedOpacity: Double

    private enum Panel {
        case timer
        case settings
        case profiles
    }

    @State private var panel = Panel.timer
    @FocusState private var isPrimaryActionFocused: Bool

    public init(
        timerStore: PomodoroStore,
        profileStore: ProfileStore,
        isPinned: Binding<Bool>,
        pinnedOpacity: Binding<Double>
    ) {
        self.timerStore = timerStore
        self.profileStore = profileStore
        _isPinned = isPinned
        _pinnedOpacity = pinnedOpacity
    }

    public var body: some View {
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
        .preferredColorScheme(.dark)
    }

    private var timerPanel: some View {
        VStack(spacing: 18) {
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(phaseColor)
                        .frame(width: 9, height: 9)
                    Text(timerStore.state.phase.displayName)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(FocusTheme.textPrimary)
                }

                Spacer()

                Text("집중 \(timerStore.state.currentFocusCount) / \(timerStore.configuration.focusCount)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(FocusTheme.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(FocusTheme.elevatedSurface, in: Capsule())
            }
            // 항상 켜두기 중에만 창 전체 투명도를 조절하는 바를 상단 정가운데에 보여 줍니다.
            .overlay {
                if isPinned {
                    Slider(value: $pinnedOpacity, in: 0.3...1)
                        .controlSize(.mini)
                        .frame(width: 96)
                        .help("투명도 \(Int((pinnedOpacity * 100).rounded()))%")
                        .accessibilityLabel("투명도")
                }
            }

            ZStack {
                Circle()
                    .stroke(FocusTheme.elevatedSurface, lineWidth: 11)

                Circle()
                    .trim(from: 0, to: max(progress, 0.02))
                    .stroke(
                        phaseColor,
                        style: StrokeStyle(lineWidth: 11, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 5) {
                    Text(timerStore.formattedTime)
                        .font(.system(size: 46, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(FocusTheme.textPrimary)
                    Text(timerStore.state.phase == .completed ? "모든 집중 완료" : "남은 시간")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(FocusTheme.textSecondary)
                }
            }
            .frame(width: 194, height: 194)

            HStack(spacing: 7) {
                ForEach(1...min(timerStore.configuration.focusCount, 8), id: \.self) { index in
                    Circle()
                        .fill(index <= timerStore.state.currentFocusCount ? phaseColor : FocusTheme.elevatedSurface)
                        .frame(width: 8, height: 8)
                }
            }

            Button {
                if timerStore.state.isRunning {
                    timerStore.pause()
                } else {
                    timerStore.start()
                }
            } label: {
                Label(primaryActionTitle, systemImage: primaryActionSymbol)
            }
            .buttonStyle(FocusPrimaryButtonStyle(tint: phaseColor))
            .focused($isPrimaryActionFocused)
            .onAppear {
                isPrimaryActionFocused = false
            }

            Text(timerStore.nextStepText)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(FocusTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)

            HStack(spacing: 10) {
                Button("중지") {
                    timerStore.reset()
                }
                .buttonStyle(FocusSecondaryButtonStyle())

                Button("설정") {
                    panel = .settings
                }
                .buttonStyle(FocusSecondaryButtonStyle())

                Button("프로필") {
                    panel = .profiles
                }
                .buttonStyle(FocusSecondaryButtonStyle())
            }

            HStack {
                Text("Focus Timer v\(AppVersion.current)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(FocusTheme.textSecondary)
                Spacer()
                Toggle("항상 켜두기", isOn: $isPinned)
                    .toggleStyle(.checkbox)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(FocusTheme.textSecondary)
                Button("종료") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(FocusCompactButtonStyle(tint: FocusTheme.danger))
                // 체크박스와 붙어 있으면 실수로 종료할 수 있어 간격을 둡니다.
                .padding(.leading, 20)
            }
        }
        .padding(22)
        .frame(width: 360)
        .background(FocusTheme.background)
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

    private var primaryActionSymbol: String {
        if timerStore.state.isRunning {
            return "pause.fill"
        }
        return "play.fill"
    }

    private var phaseColor: Color {
        switch timerStore.state.phase {
        case .focus:
            return FocusTheme.mint
        case .breakTime:
            return FocusTheme.rest
        case .completed:
            return FocusTheme.mint
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

    private var progress: CGFloat {
        guard totalSeconds > 0 else {
            return 0
        }
        return min(1, max(0, (totalSeconds - Double(timerStore.state.remainingSeconds)) / totalSeconds))
    }
}
