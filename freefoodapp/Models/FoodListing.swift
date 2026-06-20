import CoreLocation
import Foundation

struct FoodListing: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var details: String
    var locationName: String
    var coordinate: Coordinate
    var date: Date
    var startTime: Date
    var endTime: Date
    var photos: [Data]
    var createdAt = Date()

    var expiresAt: Date {
        Calendar.current.date(byAdding: .day, value: 7, to: createdAt) ?? createdAt
    }

    var combinedStartDate: Date {
        Calendar.current.date(
            bySettingHour: Calendar.current.component(.hour, from: startTime),
            minute: Calendar.current.component(.minute, from: startTime),
            second: 0,
            of: date
        ) ?? date
    }

    var combinedEndDate: Date {
        Calendar.current.date(
            bySettingHour: Calendar.current.component(.hour, from: endTime),
            minute: Calendar.current.component(.minute, from: endTime),
            second: 0,
            of: date
        ) ?? date
    }

    /// A past event: the food's end time has already passed, so it's no longer available.
    var hasEnded: Bool { combinedEndDate < .now }

    /// Shown in the shared feed only while the event is still upcoming/ongoing
    /// (not a past event) and the post is less than 7 days old. Anything else is purged.
    var isActive: Bool { !hasEnded && expiresAt > .now }

    func distance(from location: CLLocation?) -> CLLocationDistance? {
        guard let location else { return nil }
        return CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            .distance(from: location)
    }
}

struct Coordinate: Codable, Hashable {
    var latitude: Double
    var longitude: Double

    var clLocationCoordinate2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

extension FoodListing {
    static let sample = FoodListing(
        title: "Pastries after meetup",
        details: "Mixed croissants and sandwiches left from a morning event. Please bring your own bag.",
        locationName: "Tanjong Pagar Centre",
        coordinate: Coordinate(latitude: 1.2764, longitude: 103.8458),
        date: .now,
        startTime: .now,
        endTime: Calendar.current.date(byAdding: .hour, value: 2, to: .now) ?? .now,
        photos: []
    )
}
