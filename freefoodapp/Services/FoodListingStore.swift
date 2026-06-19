import CloudKit
import Foundation

/// Shared store backed by the **CloudKit public database** so every user sees the
/// same listings. Anyone can browse without an iCloud account; posting requires the
/// device to be signed into iCloud (CloudKit public-database write rule).
@MainActor
final class FoodListingStore: ObservableObject {
    @Published private(set) var listings: [FoodListing] = []
    @Published private(set) var isLoading = false
    /// User-facing message for the last sync/post problem (e.g. not signed into iCloud).
    @Published var statusMessage: String?

    static let containerIdentifier = "iCloud.com.tertiaryinfotech.freefood"
    private let recordType = "FoodListing"
    private let container = CKContainer(identifier: FoodListingStore.containerIdentifier)
    private var publicDB: CKDatabase { container.publicCloudDatabase }

    init() {
        Task { await refresh() }
    }

    // MARK: - Reads (already-fetched, in-memory)

    var sortedByDate: [FoodListing] {
        listings
            .filter { $0.expiresAt > .now }
            .sorted { $0.combinedStartDate < $1.combinedStartDate }
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

    /// Kept for source compatibility with callers; pruning happens on fetch.
    func purgeExpiredIfNeeded(now: Date = .now) {
        let active = listings.filter { $0.expiresAt > now }
        if active.count != listings.count { listings = active }
    }

    // MARK: - CloudKit sync

    /// Pull the latest public listings into `listings`.
    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
            query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            let (matchResults, _) = try await publicDB.records(matching: query, resultsLimit: 200)
            let fetched = matchResults.compactMap { _, result -> FoodListing? in
                guard let record = try? result.get() else { return nil }
                return FoodListing(record: record)
            }
            listings = fetched.filter { $0.expiresAt > .now }
            statusMessage = nil
        } catch let error as CKError where error.code == .unknownItem {
            // No records / schema not yet created in this environment — treat as empty.
            listings = []
            statusMessage = nil
        } catch {
            statusMessage = "Couldn't load shared listings. Pull to refresh."
        }
    }

    func add(_ listing: FoodListing) {
        // Optimistic local insert so the UI updates immediately.
        listings.insert(listing, at: 0)
        Task {
            do {
                let record = try listing.toRecord()
                _ = try await publicDB.save(record)
                await refresh()
            } catch let error as CKError where error.code == .notAuthenticated {
                listings.removeAll { $0.id == listing.id }
                statusMessage = "Sign in to iCloud (Settings → your name → iCloud) to share food."
            } catch {
                listings.removeAll { $0.id == listing.id }
                statusMessage = "Couldn't share that listing. Please try again."
            }
        }
    }

    func delete(_ listing: FoodListing) {
        listings.removeAll { $0.id == listing.id }
        Task {
            do {
                try await publicDB.deleteRecord(withID: CKRecord.ID(recordName: listing.id.uuidString))
            } catch {
                // A record created by another user can't be deleted; re-sync to restore truth.
                await refresh()
            }
        }
    }
}
