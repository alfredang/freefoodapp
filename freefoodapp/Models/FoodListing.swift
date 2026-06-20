import CoreLocation
import Foundation

/// How often a free-food giveaway repeats. Lets shops/bakeries/stalls post once for a
/// regular giveaway instead of re-creating a listing every time.
enum Recurrence: String, Codable, Hashable, CaseIterable, Identifiable {
    case none, daily, weekly

    var id: String { rawValue }
    var label: String {
        switch self {
        case .none: return "One-time"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        }
    }
}

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
    var recurrence: Recurrence = .none
    var likes: Int = 0
    /// ISO country code (e.g. "SG") of the pickup location, for country-based filtering.
    var country: String = ""
    var createdAt = Date()

    var expiresAt: Date {
        Calendar.current.date(byAdding: .day, value: 7, to: createdAt) ?? createdAt
    }

    private func combine(_ time: Date, on day: Date) -> Date {
        Calendar.current.date(
            bySettingHour: Calendar.current.component(.hour, from: time),
            minute: Calendar.current.component(.minute, from: time),
            second: 0,
            of: day
        ) ?? day
    }

    /// For recurring listings, the next occurrence whose end time is still in the future;
    /// for one-time listings, just `date`.
    var effectiveDate: Date {
        guard recurrence != .none else { return date }
        let cal = Calendar.current
        let unit: Calendar.Component = recurrence == .daily ? .day : .weekOfYear
        var day = date
        var guardCount = 0
        while combine(endTime, on: day) < .now, guardCount < 1000 {
            guard let next = cal.date(byAdding: unit, value: 1, to: day) else { break }
            day = next
            guardCount += 1
        }
        return day
    }

    var combinedStartDate: Date { combine(startTime, on: effectiveDate) }
    var combinedEndDate: Date { combine(endTime, on: effectiveDate) }

    /// A past event: the food's end time has already passed (for recurring listings the
    /// date rolls forward, so they don't count as ended).
    var hasEnded: Bool { combinedEndDate < .now }

    /// Recurring listings stay live indefinitely (they keep rolling forward). One-time
    /// listings are shown only while upcoming/ongoing and posted within the last 7 days.
    var isActive: Bool {
        recurrence != .none ? true : (!hasEnded && expiresAt > .now)
    }

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
