import SwiftUI

@main
struct FreeFoodApp: App {
    @StateObject private var store = FoodListingStore()
    @StateObject private var locationManager = LocationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(locationManager)
        }
    }
}
