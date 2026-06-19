import MapKit
import SwiftUI

struct FoodMapView: View {
    let listings: [FoodListing]
    @State private var camera: MapCameraPosition = .automatic
    @State private var selectedListing: FoodListing?

    var body: some View {
        Map(position: $camera, selection: $selectedListing) {
            ForEach(listings) { listing in
                Marker(listing.title, systemImage: "fork.knife", coordinate: listing.coordinate.clLocationCoordinate2D)
                    .tag(listing)
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .safeAreaInset(edge: .bottom) {
            if let selectedListing {
                NavigationLink(value: selectedListing) {
                    HStack(spacing: 12) {
                        ListingThumbnail(data: selectedListing.photos.first)
                            .frame(width: 58, height: 58)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedListing.title)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(selectedListing.locationName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding()
                }
            }
        }
        .navigationDestination(for: FoodListing.self) { listing in
            ListingDetailView(listing: listing)
        }
    }
}
