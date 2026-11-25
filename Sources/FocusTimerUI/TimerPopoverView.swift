import AppKit
import SwiftUI
import FocusTimerCore

public struct TimerPopoverView: View {
    @ObservedObject var timerStore: PomodoroStore
    @ObservedObject var profileStore: ProfileStore
    @Binding var isPinned: Bool
    @Binding var pinnedOpacity: Double
    let flashCount: Int
    let flashAlert: TimerAlert?

    private enum Panel {
        case timer
        case settings
        case profiles
    }

    @State private var panel = Panel.timer
    @FocusState private var isPrimaryActionFocused: Bool
    @State private var flashOpacity = 0.0
    @State private var isFlashStopped = false

    /// 3회 번쩍인 뒤 마지막은 문구를 읽도록 잠시 머물렀다 사라집니다. 약 0.5초 간격이라 초당 3회 이하(광과민성 기준)입니다.
    private static let flashSteps: [(opacity: Double, milliseconds: UInt64)] = [
        (0.94, 300), (0, 220), (0.94, 300), (0, 220), (0.94, 1_160), (0, 400)
    ]
    /// 동작 줄이기 중에는 깜빡이지 않고 한 번만 보여 줍니다. 길이는 flashSteps와 같습니다.
    private static let gentleFlashSteps: [(opacity: Double, milliseconds: UInt64)] = [(0.94, 2_200), (0, 400)]
    static let flashDuration = TimeInterval(flashSteps.map(\.milliseconds).reduce(0, +)) / 1_000

    public init(
        timerStore: PomodoroStore,
        profileStore: ProfileStore,
        isPinned: Binding<Bool>,
        pinnedOpacity: Binding<Double>,
        flashCount: Int = 0,
        flashAlert: TimerAlert? = nil
    ) {
        self.timerStore = timerStore
        self.profileStore = profileStore
        _isPinned = isPinned
        _pinnedOpacity = pinnedOpacity
        self.flashCount = flashCount
        self.flashAlert = flashAlert
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
        .overlay { flashOverlay }
        .task(id: flashCount) {
            guard flashCount > 0, flashAlert != nil else {
                return
            }
            await playFlash()
        }
        .preferredColorScheme(.dark)
    }

    /// 단계 색으로 창 전체를 덮어 막 시작한 단계를 크게 알리고, 끝나면 창이 닫힐 때까지 단계 색 테두리를 남깁니다.
    private var flashOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(phaseColor, lineWidth: 2)
                .opacity(flashAlert == nil ? 0 : 1)
                .allowsHitTesting(false)

            VStack(spacing: 4) {
                Text(flashAlert?.flashTitle ?? "")
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                Text(flashAlert?.flashSubtitle ?? "")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .opacity(0.78)
            }
            .foregroundStyle(FocusTheme.ink)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(phaseColor)
            .opacity(flashOpacity)
            // 문구에 가려 보이지 않는 중지·종료 버튼이 눌리지 않도록, 깜빡이는 동안의 클릭은 깜빡임만 멈춥니다.
            .contentShape(Rectangle())
            .onTapGesture {
                isFlashStopped = true
                flashOpacity = 0
            }
            .allowsHitTesting(flashOpacity > 0)
        }
    }

    private func playFlash() async {
        isFlashStopped = false
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        for step in reduceMotion ? Self.gentleFlashSteps : Self.flashSteps where !isFlashStopped {
            withAnimation(.easeInOut(duration: reduceMotion ? 0.3 : 0.08)) {
                flashOpacity = step.opacity
            }
            try? await Task.sleep(nanoseconds: step.milliseconds * 1_000_000)
        }
        flashOpacity = 0
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

            VStack(spacing: 4) {
                Text(timerStore.nextStepText)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(FocusTheme.textSecondary)

                if timerStore.state.phase != .completed {
                    // 대기·일시정지 중에는 시계만 흐르므로 1분마다 완료 예정 시각을 다시 계산합니다.
                    TimelineView(.everyMinute) { _ in
                        Text(timerStore.finishTimeText)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(phaseColor)
                    }
                }
            }
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
