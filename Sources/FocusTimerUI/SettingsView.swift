import SwiftUI
import FocusTimerCore

public struct SettingsView: View {
    @ObservedObject var timerStore: PomodoroStore
    let onClose: () -> Void

    public init(timerStore: PomodoroStore, onClose: @escaping () -> Void) {
        self.timerStore = timerStore
        self.onClose = onClose
    }

    @State private var focusMinutes = ""
    @State private var breakMinutes = ""
    @State private var focusCount = ""
    @State private var soundEnabled = true
    @State private var notificationsEnabled = true
    @State private var soundChoice = AlertSoundChoice.appDefault
    @State private var soundRepeatCount = AlertSettings().soundRepeatCount
    @State private var validationMessage: String?

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            VStack(spacing: 10) {
                numberField(title: "집중 시간", text: $focusMinutes, unit: "분")
                numberField(title: "휴식 시간", text: $breakMinutes, unit: "분")
                numberField(title: "집중 횟수", text: $focusCount, unit: "회")
            }
            .opacity(timerStore.state.isRunning ? 0.45 : 1)
            .allowsHitTesting(!timerStore.state.isRunning)

            VStack(spacing: 0) {
                toggleRow(title: "소리 알림", isOn: $soundEnabled)
                Divider().overlay(FocusTheme.border)
                toggleRow(title: "macOS 알림", isOn: $notificationsEnabled)
            }
            .padding(.horizontal, 14)
            .background(FocusTheme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(timerStore.state.isRunning ? 0.45 : 1)
            .allowsHitTesting(!timerStore.state.isRunning)

            HStack {
                Text("알림 사운드")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(FocusTheme.textPrimary)
                Spacer()
                Picker("알림 사운드", selection: $soundChoice) {
                    ForEach(AlertSoundChoice.allCases) { choice in
                        Text(choice.displayName).tag(choice)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 178)
                .disabled(!soundEnabled)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(FocusTheme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(timerStore.state.isRunning || !soundEnabled ? 0.45 : 1)
            .allowsHitTesting(!timerStore.state.isRunning)

            HStack {
                Text("소리 반복")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(FocusTheme.textPrimary)
                Spacer()
                Picker("소리 반복", selection: $soundRepeatCount) {
                    ForEach(AlertSettings.soundRepeatRange, id: \.self) { count in
                        Text("\(count)회").tag(count)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 178)
                .disabled(!soundEnabled)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(FocusTheme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(timerStore.state.isRunning || !soundEnabled ? 0.45 : 1)
            .allowsHitTesting(!timerStore.state.isRunning)

            Button("소리 미리 듣기") {
                timerStore.previewSound(soundChoice, repeatCount: soundRepeatCount)
            }
            .buttonStyle(FocusSecondaryButtonStyle())

            Text("미리 듣기 소리가 들리지 않으면 macOS 사운드 출력 장치와 앱 볼륨을 확인하세요.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(FocusTheme.textSecondary)

            if timerStore.state.isRunning {
                notice("실행 중에는 일시정지하거나 중지한 뒤 타이머 설정을 바꿀 수 있습니다.")
            }

            if let validationMessage {
                notice(validationMessage, color: FocusTheme.danger)
            }

            HStack(spacing: 10) {
                Button("취소") {
                    onClose()
                }
                .buttonStyle(FocusSecondaryButtonStyle())

                Button("적용") {
                    apply()
                }
                .buttonStyle(FocusPrimaryButtonStyle())
                .disabled(timerStore.state.isRunning)
                .opacity(timerStore.state.isRunning ? 0.45 : 1)
            }
        }
        .padding(22)
        .frame(width: 360)
        .background(FocusTheme.background)
        .preferredColorScheme(.dark)
        .onAppear(perform: loadCurrentValues)
    }

    private var header: some View {
        HStack {
            Button {
                onClose()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 32, height: 32)
                    .background(FocusTheme.surface, in: Circle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(FocusTheme.textPrimary)

            Text("설정")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(FocusTheme.textPrimary)

            Spacer()
        }
    }

    private func numberField(title: String, text: Binding<String>, unit: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(FocusTheme.textPrimary)
            Spacer()
            TextField("", text: text)
                .textFieldStyle(.plain)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(FocusTheme.textPrimary)
                .frame(width: 72)
            Text(unit)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(FocusTheme.textSecondary)
                .frame(width: 22, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(FocusTheme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(FocusTheme.border, lineWidth: 1)
        }
    }

    private func toggleRow(title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(FocusTheme.textPrimary)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(FocusTheme.mint)
        }
        .padding(.vertical, 10)
    }

    private func notice(_ text: String, color: Color = FocusTheme.textSecondary) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(color)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func loadCurrentValues() {
        let configuration = timerStore.configuration
        focusMinutes = String(configuration.focusMinutes)
        breakMinutes = String(configuration.breakMinutes)
        focusCount = String(configuration.focusCount)
        soundEnabled = timerStore.alertSettings.soundEnabled
        notificationsEnabled = timerStore.alertSettings.notificationsEnabled
        soundChoice = timerStore.alertSettings.soundChoice
        soundRepeatCount = timerStore.alertSettings.soundRepeatCount
        validationMessage = nil
    }

    private func apply() {
        guard
            let focus = Int(focusMinutes),
            let rest = Int(breakMinutes),
            let count = Int(focusCount),
            let configuration = TimerConfiguration(focusMinutes: focus, breakMinutes: rest, focusCount: count)
        else {
            validationMessage = "집중 시간, 휴식 시간, 집중 횟수에는 1 이상의 정수를 입력하세요."
            return
        }

        timerStore.apply(
            configuration: configuration,
            alertSettings: AlertSettings(
                soundEnabled: soundEnabled,
                notificationsEnabled: notificationsEnabled,
                soundChoice: soundChoice,
                soundRepeatCount: soundRepeatCount
            )
        )
        onClose()
    }
}
