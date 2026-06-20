import MapKit
import PhotosUI
import SwiftUI

struct AddListingView: View {
    @EnvironmentObject private var store: FoodListingStore
    @Environment(\.dismiss) private var dismiss

    @StateObject private var searchService = LocationSearchService()
    @State private var title = ""
    @State private var details = ""
    @State private var date = Date()
    @State private var startTime = Date()
    @State private var endTime = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
    @State private var recurrence: Recurrence = .none
    @State private var selectedLocationName = ""
    @State private var selectedCoordinate: Coordinate?
    @State private var selectedCountry = ""
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var photos: [Data] = []
    @State private var locationTask: Task<Void, Never>?

    // Lightweight human check to deter bots / fake listings.
    @State private var challenge = AddListingView.makeChallenge()
    @State private var challengeAnswer = ""

    private var humanVerified: Bool {
        challengeAnswer.trimmingCharacters(in: .whitespaces).uppercased() == challenge
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedCoordinate != nil &&
        endTime > startTime &&
        humanVerified
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label(
                        "FreeFood helps reduce food waste. Please post only real, available food — don't create fictitious events.",
                        systemImage: "leaf.fill"
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }

                Section("Photos") {
                    PhotosPicker(selection: $photoItems, maxSelectionCount: 3, matching: .images) {
                        Label("Choose up to 3 photos", systemImage: "photo.on.rectangle.angled")
                    }

                    if !photos.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Array(photos.enumerated()), id: \.offset) { _, data in
                                    ListingThumbnail(data: data)
                                        .frame(width: 88, height: 88)
                                }
                            }
                        }
                    }
                }

                Section {
                    TextField("Food title", text: $title)
                    TextField("Event details", text: $details, axis: .vertical)
                        .lineLimit(3...6)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    DatePicker("Start time", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End time", selection: $endTime, displayedComponents: .hourAndMinute)
                    Picker("Repeats", selection: $recurrence) {
                        ForEach(Recurrence.allCases) { r in
                            Text(r.label).tag(r)
                        }
                    }
                } header: {
                    Text("Event")
                } footer: {
                    if recurrence != .none {
                        Text("Recurring giveaways stay listed and roll forward to the next \(recurrence == .daily ? "day" : "week"). Great for bakeries and stalls.")
                    }
                }

                Section("Location") {
                    TextField("Search location", text: $searchService.query)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.search)
                        .onSubmit { runLocationSearch() }

                    Button {
                        runLocationSearch()
                    } label: {
                        Label("Search Apple Maps", systemImage: "magnifyingglass")
                    }

                    ForEach(searchService.results.prefix(6), id: \.self) { item in
                        Button {
                            select(item)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name ?? "Selected location")
                                    .foregroundStyle(.primary)
                                Text(address(for: item))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    if !selectedLocationName.isEmpty {
                        Label(selectedLocationName, systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }

                Section("Quick human check") {
                    HStack {
                        Text(challenge)
                            .font(.system(.title2, design: .monospaced).weight(.bold))
                            .tracking(6)
                            .strikethrough(color: .secondary.opacity(0.4))
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(.gray.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                        Button {
                            challenge = AddListingView.makeChallenge()
                            challengeAnswer = ""
                        } label: { Image(systemName: "arrow.clockwise") }
                        .buttonStyle(.borderless)
                    }
                    TextField("Type the code above", text: $challengeAnswer)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }
            }
            .navigationTitle("Share food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
            .onChange(of: photoItems) { _, newValue in
                Task { await loadPhotos(from: newValue) }
            }
        }
    }

    private static func makeChallenge() -> String {
        let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<4).map { _ in chars.randomElement()! })
    }

    private func runLocationSearch() {
        locationTask?.cancel()
        locationTask = Task {
            await searchService.search()
        }
    }

    private func select(_ item: MKMapItem) {
        selectedLocationName = item.name ?? address(for: item)
        selectedCoordinate = Coordinate(
            latitude: item.placemark.coordinate.latitude,
            longitude: item.placemark.coordinate.longitude
        )
        selectedCountry = item.placemark.isoCountryCode ?? ""
        searchService.query = selectedLocationName
        searchService.results = []
    }

    private func address(for item: MKMapItem) -> String {
        let placemark = item.placemark
        return [
            placemark.thoroughfare,
            placemark.locality,
            placemark.administrativeArea,
            placemark.country
        ]
        .compactMap { $0 }
        .joined(separator: ", ")
    }

    private func loadPhotos(from items: [PhotosPickerItem]) async {
        var loaded: [Data] = []
        for item in items.prefix(3) {
            if let data = try? await item.loadTransferable(type: Data.self) {
                loaded.append(data)
            }
        }
        photos = loaded
    }

    private func save() {
        guard let selectedCoordinate else { return }
        store.add(FoodListing(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            details: details.trimmingCharacters(in: .whitespacesAndNewlines),
            locationName: selectedLocationName,
            coordinate: selectedCoordinate,
            date: date,
            startTime: startTime,
            endTime: endTime,
            photos: Array(photos.prefix(3)),
            recurrence: recurrence,
            country: selectedCountry
        ))
        dismiss()
    }
}
