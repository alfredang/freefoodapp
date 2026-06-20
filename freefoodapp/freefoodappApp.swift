import SwiftUI

@main
struct FreeFoodApp: App {
    @StateObject private var store = FoodListingStore()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(locationManager)
                .environmentObject(settings)
        }
    }
}
