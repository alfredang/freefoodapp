import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: FoodListingStore
    @EnvironmentObject private var locationManager: LocationManager
    @State private var searchText = ""
    @State private var showingAddListing = false
    @State private var selectedTab = 0

    private var dateSortedListings: [FoodListing] {
        store.search(searchText)
    }

    private var nearestListing: FoodListing? {
        guard locationManager.currentLocation != nil else { return dateSortedListings.first }
        return dateSortedListings.min {
            ($0.distance(from: locationManager.currentLocation) ?? .greatestFiniteMagnitude) <
            ($1.distance(from: locationManager.currentLocation) ?? .greatestFiniteMagnitude)
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ListingFeedView(nearestListing: nearestListing, listings: dateSortedListings, searchText: $searchText)
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
                FoodMapView(listings: dateSortedListings)
                    .navigationTitle("Map")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem { Label("Map", systemImage: "map") }
            .tag(1)
        }
        .sheet(isPresented: $showingAddListing) {
            AddListingView()
        }
        .task {
            locationManager.requestLocation()
            store.purgeExpiredIfNeeded()
        }
    }
}
