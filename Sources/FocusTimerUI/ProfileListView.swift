import SwiftUI
import FocusTimerCore

public struct ProfileListView: View {
    @ObservedObject var timerStore: PomodoroStore
    @ObservedObject var profileStore: ProfileStore
    let onClose: () -> Void

    public init(timerStore: PomodoroStore, profileStore: ProfileStore, onClose: @escaping () -> Void) {
        self.timerStore = timerStore
        self.profileStore = profileStore
        self.onClose = onClose
    }

    @State private var profileName = ""
    @State private var validationMessage: String?
    @State private var profileToDelete: TimerProfile?

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            Text("반복해서 쓰는 집중 계획을 저장하고 한 번에 시작하세요.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(FocusTheme.textSecondary)

            if profileStore.profiles.isEmpty {
                Text("아직 저장된 프로필이 없습니다.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(FocusTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 26)
                    .background(FocusTheme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                ScrollView {
                    LazyVStack(spacing: 9) {
                        ForEach(profileStore.profiles) { profile in
                            profileCard(profile)
                        }
                    }
                }
                .frame(minHeight: 106, maxHeight: 230)
            }

            if let profileToDelete {
                VStack(alignment: .leading, spacing: 10) {
                    Text("‘\(profileToDelete.name)’ 프로필을 삭제할까요?")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(FocusTheme.textPrimary)
                    HStack(spacing: 10) {
                        Button("취소") {
                            self.profileToDelete = nil
                        }
                        .buttonStyle(FocusSecondaryButtonStyle())

                        Button("삭제") {
                            profileStore.delete(id: profileToDelete.id)
                            self.profileToDelete = nil
                        }
                        .buttonStyle(FocusPrimaryButtonStyle(tint: FocusTheme.danger))
                    }
                }
                .padding(13)
                .background(FocusTheme.danger.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            Divider().overlay(FocusTheme.border)

            Text("현재 설정을 프로필로 저장")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(FocusTheme.textPrimary)

            TextField("프로필 이름", text: $profileName)
                .textFieldStyle(.plain)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(FocusTheme.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(FocusTheme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(FocusTheme.border, lineWidth: 1)
                }
                .disabled(timerStore.state.isRunning || !profileStore.canSaveAnotherProfile)
                .opacity(timerStore.state.isRunning || !profileStore.canSaveAnotherProfile ? 0.45 : 1)

            Text(summary(for: timerStore.configuration))
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(FocusTheme.textSecondary)

            if !profileStore.canSaveAnotherProfile {
                notice("프로필은 최대 10개입니다. 삭제 후 새로 저장하세요.")
            }

            if timerStore.state.isRunning {
                notice("실행 중에는 현재 설정을 새 프로필로 저장할 수 없습니다.")
            }

            if let validationMessage {
                notice(validationMessage, color: FocusTheme.danger)
            }

            Button("프로필 저장") {
                saveProfile()
            }
            .buttonStyle(FocusPrimaryButtonStyle())
            .disabled(timerStore.state.isRunning || !profileStore.canSaveAnotherProfile)
            .opacity(timerStore.state.isRunning || !profileStore.canSaveAnotherProfile ? 0.45 : 1)
        }
        .padding(22)
        .frame(width: 390)
        .background(FocusTheme.background)
        .preferredColorScheme(.dark)
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

            Text("프로필")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(FocusTheme.textPrimary)

            Spacer()

            Text("\(profileStore.profiles.count) / \(ProfileStore.maximumProfiles)")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(FocusTheme.mint)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(FocusTheme.mintMuted, in: Capsule())
        }
    }

    private func profileCard(_ profile: TimerProfile) -> some View {
        HStack(spacing: 11) {
            Circle()
                .fill(FocusTheme.mint)
                .frame(width: 9, height: 9)

            VStack(alignment: .leading, spacing: 4) {
                Text(profile.name)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(FocusTheme.textPrimary)
                Text(summary(for: profile.configuration))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(FocusTheme.textSecondary)
            }

            Spacer(minLength: 0)

            Button("실행") {
                timerStore.start(profile: profile)
                onClose()
            }
            .buttonStyle(FocusCompactButtonStyle())

            Button {
                profileToDelete = profile
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(FocusTheme.textSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(profile.name) 삭제")
        }
        .padding(12)
        .background(FocusTheme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(FocusTheme.border, lineWidth: 1)
        }
    }

    private func summary(for configuration: TimerConfiguration) -> String {
        "집중 \(configuration.focusMinutes)분 · 휴식 \(configuration.breakMinutes)분 · 집중 \(configuration.focusCount)회"
    }

    private func notice(_ text: String, color: Color = FocusTheme.textSecondary) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(color)
            .padding(11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
