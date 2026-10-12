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
    @State private var profileToEdit: TimerProfile?
    @State private var editName = ""
    @State private var editFocusMinutes = ""
    @State private var editBreakMinutes = ""
    @State private var editFocusCount = ""

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

            // 수정 중에는 이름 입력란이 두 개 보이지 않도록 저장 영역 대신 수정 폼을 보여 줍니다.
            if let profileToEdit {
                editForm(profileToEdit)
            } else {
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
                Text("총 \(profile.configuration.totalDurationText) 소요")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(FocusTheme.mint)
            }

            Spacer(minLength: 0)

            Button("실행") {
                timerStore.start(profile: profile)
                onClose()
            }
            .buttonStyle(FocusCompactButtonStyle())

            Button {
                beginEditing(profile)
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(FocusTheme.textSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(profile.name) 수정")

            Button {
                profileToEdit = nil
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

    private func editForm(_ profile: TimerProfile) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("‘\(profile.name)’ 프로필 수정")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(FocusTheme.textPrimary)

            TextField("프로필 이름", text: $editName)
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

            numberField(title: "집중 시간", text: $editFocusMinutes, unit: "분")
            numberField(title: "휴식 시간", text: $editBreakMinutes, unit: "분")
            numberField(title: "집중 횟수", text: $editFocusCount, unit: "회")

            if let validationMessage {
                notice(validationMessage, color: FocusTheme.danger)
            }

            HStack(spacing: 10) {
                Button("취소") {
                    profileToEdit = nil
                    validationMessage = nil
                }
                .buttonStyle(FocusSecondaryButtonStyle())

                Button("수정 저장") {
                    updateProfile(profile)
                }
                .buttonStyle(FocusPrimaryButtonStyle())
            }
        }
    }

    private func numberField(title: String, text: Binding<String>, unit: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(FocusTheme.textPrimary)
            Spacer()
            TextField("", text: text)
                .textFieldStyle(.plain)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(FocusTheme.textPrimary)
                .frame(width: 72)
            Text(unit)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(FocusTheme.textSecondary)
                .frame(width: 22, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
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

    private func beginEditing(_ profile: TimerProfile) {
        profileToDelete = nil
        profileToEdit = profile
        editName = profile.name
        editFocusMinutes = String(profile.configuration.focusMinutes)
        editBreakMinutes = String(profile.configuration.breakMinutes)
        editFocusCount = String(profile.configuration.focusCount)
        validationMessage = nil
    }

    private func updateProfile(_ profile: TimerProfile) {
        guard
            let focus = Int(editFocusMinutes),
            let rest = Int(editBreakMinutes),
            let count = Int(editFocusCount),
            let configuration = TimerConfiguration(focusMinutes: focus, breakMinutes: rest, focusCount: count)
        else {
            validationMessage = "집중 시간, 휴식 시간, 집중 횟수에는 1 이상의 정수를 입력하세요."
            return
        }

        switch profileStore.update(id: profile.id, name: editName, configuration: configuration) {
        case .success:
            profileToEdit = nil
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
        case .profileNotFound:
            return "이미 삭제된 프로필입니다."
        }
    }
}
