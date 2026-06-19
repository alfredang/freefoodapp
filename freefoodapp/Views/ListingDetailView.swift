import MapKit
import SwiftUI

struct ListingDetailView: View {
    @EnvironmentObject private var store: FoodListingStore
    @Environment(\.dismiss) private var dismiss
    let listing: FoodListing

    @State private var camera: MapCameraPosition

    init(listing: FoodListing) {
        self.listing = listing
        _camera = State(initialValue: .region(MKCoordinateRegion(
            center: listing.coordinate.clLocationCoordinate2D,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                photoStrip

                VStack(alignment: .leading, spacing: 10) {
                    Text(listing.title)
                        .font(.title2.bold())
                    Text(listing.details)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

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
