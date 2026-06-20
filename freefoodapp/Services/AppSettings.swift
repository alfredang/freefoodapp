import Foundation

/// User preferences (persisted in UserDefaults): which country and distance to show,
/// plus which recurring listings the user subscribed to and which they liked.
@MainActor
final class AppSettings: ObservableObject {
    @Published var onlyMyCountry: Bool { didSet { store.set(onlyMyCountry, forKey: Keys.onlyMyCountry) } }
    @Published var limitDistance: Bool { didSet { store.set(limitDistance, forKey: Keys.limitDistance) } }
    @Published var maxDistanceKm: Double { didSet { store.set(maxDistanceKm, forKey: Keys.maxDistanceKm) } }
    @Published var subscribedIDs: Set<String> { didSet { store.set(Array(subscribedIDs), forKey: Keys.subscribed) } }
    @Published var likedIDs: Set<String> { didSet { store.set(Array(likedIDs), forKey: Keys.liked) } }

    private let store = UserDefaults.standard
    private enum Keys {
        static let onlyMyCountry = "onlyMyCountry"
        static let limitDistance = "limitDistance"
        static let maxDistanceKm = "maxDistanceKm"
        static let subscribed = "subscribedIDs"
        static let liked = "likedIDs"
    }

    /// The user's country, inferred from the device region (e.g. "SG").
    let myCountry: String = Locale.current.region?.identifier ?? ""

    init() {
        onlyMyCountry = store.object(forKey: Keys.onlyMyCountry) as? Bool ?? true
        limitDistance = store.object(forKey: Keys.limitDistance) as? Bool ?? true
        maxDistanceKm = store.object(forKey: Keys.maxDistanceKm) as? Double ?? 10
        subscribedIDs = Set(store.stringArray(forKey: Keys.subscribed) ?? [])
        likedIDs = Set(store.stringArray(forKey: Keys.liked) ?? [])
    }

    // MARK: Subscriptions (to recurring giveaways)

    func isSubscribed(_ id: UUID) -> Bool { subscribedIDs.contains(id.uuidString) }

    func toggleSubscribe(_ id: UUID) {
        if !subscribedIDs.insert(id.uuidString).inserted {
            subscribedIDs.remove(id.uuidString)
        }
    }

    // MARK: Likes (one per device)

    func hasLiked(_ id: UUID) -> Bool { likedIDs.contains(id.uuidString) }

    func markLiked(_ id: UUID) { likedIDs.insert(id.uuidString) }
}
