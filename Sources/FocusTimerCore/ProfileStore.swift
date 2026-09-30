import Combine
import Foundation

public enum ProfileStoreError: Error, Equatable {
    case emptyName
    case duplicateName
    case maximumProfilesReached
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
