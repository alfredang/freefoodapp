import Foundation

@MainActor
final class FoodListingStore: ObservableObject {
    @Published private(set) var listings: [FoodListing] = []

    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        let supportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let appURL = supportURL.appendingPathComponent("FreeFood", isDirectory: true)
        try? FileManager.default.createDirectory(at: appURL, withIntermediateDirectories: true)
        fileURL = appURL.appendingPathComponent("listings.json")

        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        load()
    }

    var sortedByDate: [FoodListing] {
        purgeExpiredIfNeeded()
        return listings.sorted { $0.combinedStartDate < $1.combinedStartDate }
    }

    func add(_ listing: FoodListing) {
        purgeExpiredIfNeeded()
        listings.append(listing)
        save()
    }

    func delete(_ listing: FoodListing) {
        listings.removeAll { $0.id == listing.id }
        save()
    }

    func search(_ query: String) -> [FoodListing] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return sortedByDate }

        return sortedByDate.filter {
            $0.locationName.localizedCaseInsensitiveContains(trimmed) ||
            $0.title.localizedCaseInsensitiveContains(trimmed) ||
            $0.details.localizedCaseInsensitiveContains(trimmed)
        }
    }

    func purgeExpiredIfNeeded(now: Date = .now) {
        let active = listings.filter { $0.expiresAt > now }
        guard active.count != listings.count else { return }
        listings = active
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else {
            listings = [FoodListing.sample]
            save()
            return
        }

        do {
            listings = try decoder.decode([FoodListing].self, from: data)
            purgeExpiredIfNeeded()
        } catch {
            listings = []
        }
    }

    private func save() {
        guard let data = try? encoder.encode(listings) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }
}
