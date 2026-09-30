import SwiftUI
import FocusTimerCore

struct SettingsView: View {
    @ObservedObject var timerStore: PomodoroStore
    let onClose: () -> Void

    @State private var focusMinutes = ""
    @State private var breakMinutes = ""
    @State private var focusCount = ""
    @State private var soundEnabled = true
    @State private var notificationsEnabled = true
    @State private var validationMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button {
                    onClose()
                } label: {
                    Label("타이머", systemImage: "chevron.left")
                }
                .buttonStyle(.plain)

                Spacer()

                Text("설정")
                    .font(.title2.weight(.semibold))
            }

            Form {
                Section("타이머") {
                    TextField("집중 시간(분)", text: $focusMinutes)
                    TextField("휴식 시간(분)", text: $breakMinutes)
                    TextField("집중 횟수", text: $focusCount)
                }

                Section("구간 종료 알림") {
                    Toggle("소리 알림", isOn: $soundEnabled)
                    Toggle("macOS 알림", isOn: $notificationsEnabled)
                }
            }
            .disabled(timerStore.state.isRunning)

            if timerStore.state.isRunning {
                Text("실행 중에는 일시정지하거나 재설정한 뒤 설정을 적용할 수 있습니다.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let validationMessage {
                Text(validationMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            HStack {
                Spacer()
                Button("취소") {
                    onClose()
                }
                Button("적용") {
                    apply()
                }
                .buttonStyle(.borderedProminent)
                .disabled(timerStore.state.isRunning)
            }
        }
        .padding(20)
        .frame(width: 380)
        .onAppear(perform: loadCurrentValues)
    }

    private func loadCurrentValues() {
        let configuration = timerStore.configuration
        focusMinutes = String(configuration.focusMinutes)
        breakMinutes = String(configuration.breakMinutes)
        focusCount = String(configuration.focusCount)
        soundEnabled = timerStore.alertSettings.soundEnabled
        notificationsEnabled = timerStore.alertSettings.notificationsEnabled
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
            alertSettings: AlertSettings(soundEnabled: soundEnabled, notificationsEnabled: notificationsEnabled)
        )
        onClose()
    }
}
