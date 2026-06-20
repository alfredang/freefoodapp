import CloudKit
import Foundation

/// Shared store backed by the **CloudKit public database** so every user sees the
/// same listings. Anyone can browse without an iCloud account; posting requires the
/// device to be signed into iCloud (CloudKit public-database write rule).
///
/// CloudKit's public database is **eventually consistent**: a record you just saved
/// is often missing from the next query for a few seconds. To stop a freshly-posted
/// listing from vanishing, locally-saved records are held in `pending` and overlaid on
/// top of query results until a fetch confirms they're visible in the cloud.
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

    /// Last result from the cloud query.
    private var fetched: [FoodListing] = []
    /// Records saved on this device that a cloud query hasn't returned yet.
    private var pending: [UUID: FoodListing] = [:]

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

    func purgeExpiredIfNeeded(now: Date = .now) {
        for (id, listing) in pending where listing.expiresAt <= now { pending[id] = nil }
        rebuild()
    }

    /// Merge cloud results with still-pending local records into the published list.
    private func rebuild() {
        var byID: [UUID: FoodListing] = [:]
        for listing in fetched { byID[listing.id] = listing }
        for (id, listing) in pending where byID[id] == nil { byID[id] = listing }
        listings = byID.values.filter { $0.expiresAt > .now }
    }

    // MARK: - CloudKit sync

    /// Pull the latest public listings, keeping any not-yet-visible local saves.
    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            // No server-side sort (avoids needing a sortable index); sorted client-side by sortedByDate.
            let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
            let (matchResults, _) = try await publicDB.records(matching: query, resultsLimit: 200)
            fetched = matchResults.compactMap { _, result -> FoodListing? in
                guard let record = try? result.get() else { return nil }
                return FoodListing(record: record)
            }
            // Any pending record the cloud now returns is confirmed — stop overlaying it.
            for id in pending.keys where fetched.contains(where: { $0.id == id }) {
                pending[id] = nil
            }
            rebuild()
            statusMessage = nil
        } catch let error as CKError where error.code == .unknownItem {
            // No records / schema not yet created in this environment — treat as empty.
            fetched = []
            rebuild()
            statusMessage = nil
        } catch {
            // Keep whatever is already on screen; just report the problem.
            statusMessage = "Couldn't load shared listings. Pull to refresh."
        }
    }

    func add(_ listing: FoodListing) {
        // Hold locally so it stays visible until the cloud query returns it.
        pending[listing.id] = listing
        rebuild()
        Task {
            do {
                let record = try listing.toRecord()
                _ = try await publicDB.save(record)
                await refresh()   // pending overlay keeps it visible until the query catches up
            } catch let error as CKError where error.code == .notAuthenticated {
                pending[listing.id] = nil
                rebuild()
                statusMessage = "Sign in to iCloud (Settings → your name → iCloud) to share food."
            } catch {
                pending[listing.id] = nil
                rebuild()
                statusMessage = "Couldn't share that listing: \(error.localizedDescription)"
            }
        }
    }

    func delete(_ listing: FoodListing) {
        pending[listing.id] = nil
        fetched.removeAll { $0.id == listing.id }
        rebuild()
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
