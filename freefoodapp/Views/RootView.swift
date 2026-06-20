import SwiftUI

/// App root: the bottom tab bar hosting Nearby, Map, Settings, Feedback, and About.
struct RootView: View {
    @EnvironmentObject private var store: FoodListingStore
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var settings: AppSettings
    @State private var searchText = ""
    @State private var showingAddListing = false
    @State private var selectedTab = 0

    /// Active listings after applying the user's country + distance filters. Subscribed
    /// recurring giveaways are always shown regardless of the filters.
    private var visibleListings: [FoodListing] {
        store.search(searchText).filter { listing in
            if settings.isSubscribed(listing.id) { return true }
            if settings.onlyMyCountry, !settings.myCountry.isEmpty,
               !listing.country.isEmpty, listing.country != settings.myCountry {
                return false
            }
            if settings.limitDistance, let loc = locationManager.currentLocation,
               let distance = listing.distance(from: loc), distance > settings.maxDistanceKm * 1_000 {
                return false
            }
            return true
        }
    }

    private var nearestListing: FoodListing? {
        guard locationManager.currentLocation != nil else { return visibleListings.first }
        return visibleListings.min {
            ($0.distance(from: locationManager.currentLocation) ?? .greatestFiniteMagnitude) <
            ($1.distance(from: locationManager.currentLocation) ?? .greatestFiniteMagnitude)
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ListingFeedView(nearestListing: nearestListing, listings: visibleListings, searchText: $searchText)
                    .navigationTitle("Free Food")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                showingAddListing = true
                            } label: {
                                Image(systemName: "plus")
                            }
                            .accessibilityLabel("Add free food")
                        }
                    }
            }
            .tabItem { Label("Nearby", systemImage: "fork.knife.circle") }
            .tag(0)

            NavigationStack {
                FoodMapView(listings: visibleListings)
                    .navigationTitle("Map")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem { Label("Map", systemImage: "map") }
            .tag(1)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(2)

            FeedbackView()
                .tabItem { Label("Feedback", systemImage: "bubble.left.and.bubble.right.fill") }
                .tag(3)

            AboutView()
                .tabItem { Label("About", systemImage: "info.circle") }
                .tag(4)
        }
        .sheet(isPresented: $showingAddListing) {
            AddListingView()
        }
        .alert(
            "Heads up",
            isPresented: Binding(
                get: { store.statusMessage != nil },
                set: { if !$0 { store.statusMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(store.statusMessage ?? "")
        }
        .task {
            locationManager.requestLocation()
            store.purgeExpiredIfNeeded()
        }
    }
}
