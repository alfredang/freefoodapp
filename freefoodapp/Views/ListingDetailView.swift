import MapKit
import SwiftUI

struct ListingDetailView: View {
    @EnvironmentObject private var store: FoodListingStore
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    let listing: FoodListing

    @State private var camera: MapCameraPosition
    @State private var likeCount: Int

    init(listing: FoodListing) {
        self.listing = listing
        _likeCount = State(initialValue: listing.likes)
        _camera = State(initialValue: .region(MKCoordinateRegion(
            center: listing.coordinate.clLocationCoordinate2D,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )))
    }

    private var shareText: String {
        var s = "Free food: \(listing.title) at \(listing.locationName) — "
        s += "\(listing.combinedStartDate.formatted(date: .abbreviated, time: .shortened))."
        if listing.recurrence != .none { s += " Repeats \(listing.recurrence.label.lowercased())." }
        s += " Shared via FreeFood to reduce food waste."
        return s
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                photoStrip

                VStack(alignment: .leading, spacing: 10) {
                    Text(listing.title)
                        .font(.title2.bold())
                    if listing.recurrence != .none {
                        Label("Repeats \(listing.recurrence.label.lowercased())", systemImage: "repeat")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(.green.opacity(0.15), in: Capsule())
                            .foregroundStyle(.green)
                    }
                    Text(listing.details)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                actionBar

                infoGrid

                Map(position: $camera) {
                    Marker(listing.title, coordinate: listing.coordinate.clLocationCoordinate2D)
                }
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Button {
                    openInMaps()
                } label: {
                    Label("Open in Apple Maps", systemImage: "map")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .navigationTitle("Food details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    store.delete(listing)
                    dismiss()
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("Delete listing")
            }
        }
    }

    private var actionBar: some View {
        HStack(spacing: 12) {
            Button {
                guard !settings.hasLiked(listing.id) else { return }
                store.like(listing)
                settings.markLiked(listing.id)
                likeCount += 1
            } label: {
                Label("\(likeCount)", systemImage: settings.hasLiked(listing.id) ? "heart.fill" : "heart")
            }
            .tint(.pink)
            .disabled(settings.hasLiked(listing.id))

            ShareLink(item: shareText) {
                Label("Share", systemImage: "square.and.arrow.up")
            }

            if listing.recurrence != .none {
                Button {
                    settings.toggleSubscribe(listing.id)
                } label: {
                    Label(settings.isSubscribed(listing.id) ? "Subscribed" : "Subscribe",
                          systemImage: settings.isSubscribed(listing.id) ? "bell.fill" : "bell")
                }
                .tint(.orange)
            }

            Spacer()
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .labelStyle(.titleAndIcon)
    }

    private var photoStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                if listing.photos.isEmpty {
                    ListingThumbnail(data: nil)
                        .frame(width: 220, height: 160)
                } else {
                    ForEach(Array(listing.photos.enumerated()), id: \.offset) { _, data in
                        ListingThumbnail(data: data)
                            .frame(width: 220, height: 160)
                    }
                }
            }
        }
    }

    private var infoGrid: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
            infoRow("Location", "mappin.and.ellipse", listing.locationName)
            infoRow("Date", "calendar", listing.date.formatted(date: .long, time: .omitted))
            infoRow("Time", "clock", "\(listing.startTime.formatted(date: .omitted, time: .shortened)) - \(listing.endTime.formatted(date: .omitted, time: .shortened))")
            infoRow("Deletes", "timer", listing.expiresAt.formatted(date: .abbreviated, time: .shortened))
        }
        .padding()
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func infoRow(_ label: String, _ icon: String, _ value: String) -> some View {
        GridRow {
            Label(label, systemImage: icon)
                .foregroundStyle(.secondary)
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }

    private func openInMaps() {
        let placemark = MKPlacemark(coordinate: listing.coordinate.clLocationCoordinate2D)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = listing.locationName
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
        ])
    }
}
