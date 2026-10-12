import Combine
import Foundation

public enum ProfileStoreError: Error, Equatable {
    case emptyName
    case duplicateName
    case maximumProfilesReached
    case profileNotFound
}

public final class ProfileStore: ObservableObject {
    public static let maximumProfiles = 10

    @Published public private(set) var profiles: [TimerProfile]

    private let defaults: UserDefaults
    private let storageKey = "FocusTimer.profiles"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        guard
            let data = defaults.data(forKey: storageKey),
            let decodedProfiles = try? JSONDecoder().decode([TimerProfile].self, from: data)
        else {
            profiles = []
            return
        }

        profiles = Array(decodedProfiles.prefix(Self.maximumProfiles))
    }

    public var canSaveAnotherProfile: Bool {
        profiles.count < Self.maximumProfiles
    }

    @discardableResult
    public func save(name: String, configuration: TimerConfiguration) -> Result<TimerProfile, ProfileStoreError> {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            return .failure(.emptyName)
        }

        guard canSaveAnotherProfile else {
            return .failure(.maximumProfilesReached)
        }

        guard !profiles.contains(where: { normalizedName($0.name) == normalizedName(trimmedName) }) else {
            return .failure(.duplicateName)
        }

        let profile = TimerProfile(name: trimmedName, configuration: configuration)
        profiles.append(profile)
        persist()
        return .success(profile)
    }

    /// 이름과 타이머 값을 바꿉니다. id와 목록 순서는 그대로 유지하고, 개수 제한은 적용하지 않습니다.
    @discardableResult
    public func update(id: UUID, name: String, configuration: TimerConfiguration) -> Result<TimerProfile, ProfileStoreError> {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            return .failure(.emptyName)
        }

        guard let index = profiles.firstIndex(where: { $0.id == id }) else {
            return .failure(.profileNotFound)
        }

        guard !profiles.contains(where: { $0.id != id && normalizedName($0.name) == normalizedName(trimmedName) }) else {
            return .failure(.duplicateName)
        }

        let profile = TimerProfile(id: id, name: trimmedName, configuration: configuration)
        profiles[index] = profile
        persist()
        return .success(profile)
    }

    public func delete(id: UUID) {
        profiles.removeAll { $0.id == id }
        persist()
    }

    private func normalizedName(_ name: String) -> String {
        name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: .current)
            .lowercased()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(profiles) else {
            return
        }
        defaults.set(data, forKey: storageKey)
    }
}
