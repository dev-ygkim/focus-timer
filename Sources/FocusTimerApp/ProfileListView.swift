import SwiftUI
import FocusTimerCore

struct ProfileListView: View {
    @ObservedObject var timerStore: PomodoroStore
    @ObservedObject var profileStore: ProfileStore
    let onClose: () -> Void

    @State private var profileName = ""
    @State private var validationMessage: String?
    @State private var profileToDelete: TimerProfile?

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

                Text("프로필")
                    .font(.title2.weight(.semibold))

                Spacer()

                Text("\(profileStore.profiles.count) / \(ProfileStore.maximumProfiles)")
                    .foregroundStyle(.secondary)
            }

            Text("프로필은 집중 시간, 휴식 시간, 집중 횟수만 저장합니다.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(profileStore.profiles) { profile in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(profile.name)
                                    .font(.headline)
                                Text(summary(for: profile.configuration))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("실행") {
                                timerStore.start(profile: profile)
                                onClose()
                            }
                            .buttonStyle(.borderedProminent)

                            Button(role: .destructive) {
                                profileToDelete = profile
                            } label: {
                                Image(systemName: "trash")
                            }
                            .accessibilityLabel("\(profile.name) 삭제")
                        }
                        .padding(10)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .frame(minHeight: 140, maxHeight: 260)

            if let profileToDelete {
                VStack(alignment: .leading, spacing: 8) {
                    Text("‘\(profileToDelete.name)’ 프로필을 삭제할까요?")
                        .font(.footnote)
                    HStack {
                        Button("취소") {
                            self.profileToDelete = nil
                        }
                        Button("삭제", role: .destructive) {
                            profileStore.delete(id: profileToDelete.id)
                            self.profileToDelete = nil
                        }
                    }
                }
                .padding(10)
                .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            }

            Divider()

            Text("현재 설정을 프로필로 저장")
                .font(.headline)
            TextField("프로필 이름", text: $profileName)
                .textFieldStyle(.roundedBorder)
                .disabled(timerStore.state.isRunning || !profileStore.canSaveAnotherProfile)

            Text(summary(for: timerStore.configuration))
                .font(.footnote)
                .foregroundStyle(.secondary)

            if !profileStore.canSaveAnotherProfile {
                Text("프로필은 최대 10개입니다. 삭제 후 새로 저장하세요.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if timerStore.state.isRunning {
                Text("실행 중에는 현재 설정을 새 프로필로 저장할 수 없습니다.")
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
                Button("닫기") {
                    onClose()
                }
                Button("프로필 저장") {
                    saveProfile()
                }
                .buttonStyle(.borderedProminent)
                .disabled(timerStore.state.isRunning || !profileStore.canSaveAnotherProfile)
            }
        }
        .padding(20)
        .frame(width: 480)
    }

    private func saveProfile() {
        switch profileStore.save(name: profileName, configuration: timerStore.configuration) {
        case .success:
            profileName = ""
            validationMessage = nil
        case let .failure(error):
            validationMessage = message(for: error)
        }
    }

    private func summary(for configuration: TimerConfiguration) -> String {
        "집중 \(configuration.focusMinutes)분 · 휴식 \(configuration.breakMinutes)분 · 집중 \(configuration.focusCount)회"
    }

    private func message(for error: ProfileStoreError) -> String {
        switch error {
        case .emptyName:
            return "프로필 이름을 입력하세요."
        case .duplicateName:
            return "같은 이름의 프로필이 이미 있습니다."
        case .maximumProfilesReached:
            return "프로필은 최대 10개입니다."
        }
    }
}
