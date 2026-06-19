import SwiftUI

struct ListingFeedView: View {
    @EnvironmentObject private var locationManager: LocationManager
    let nearestListing: FoodListing?
    let listings: [FoodListing]
    @Binding var searchText: String

    var body: some View {
        List {
            if let nearest = nearestListing {
                Section("Nearest free food") {
                    NavigationLink(value: nearest) {
                        ListingRow(listing: nearest, prominence: .featured)
                    }
                }
            }

            Section("All listings") {
                if listings.isEmpty {
                    ContentUnavailableView(
                        "No food found",
                        systemImage: "magnifyingglass",
                        description: Text("Try another location or add a listing.")
                    )
                } else {
                    ForEach(listings) { listing in
                        NavigationLink(value: listing) {
                            ListingRow(listing: listing)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: "Search by location")
        .navigationDestination(for: FoodListing.self) { listing in
            ListingDetailView(listing: listing)
        }
        .refreshable {
            locationManager.requestLocation()
        }
    }
}

private struct ListingRow: View {
    enum Prominence {
        case normal
        case featured
    }

    @EnvironmentObject private var locationManager: LocationManager
    let listing: FoodListing
    var prominence: Prominence = .normal

    var body: some View {
        HStack(spacing: 12) {
            ListingThumbnail(data: listing.photos.first)
                .frame(width: prominence == .featured ? 74 : 56, height: prominence == .featured ? 74 : 56)

            VStack(alignment: .leading, spacing: 5) {
                Text(listing.title)
                    .font(prominence == .featured ? .headline : .subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Label(listing.locationName, systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Label(listing.combinedStartDate.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                    if let distance = listing.distance(from: locationManager.currentLocation) {
                        Text(distanceText(distance))
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private func distanceText(_ distance: Double) -> String {
        if distance >= 1_000 {
            return String(format: "%.1f km", distance / 1_000)
        }
        return "\(Int(distance)) m"
    }
}

struct ListingThumbnail: View {
    let data: Data?

    var body: some View {
        Group {
            if let data, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.green.opacity(0.12))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
