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
    @State private var selectedLocationName = ""
    @State private var selectedCoordinate: Coordinate?
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var photos: [Data] = []
    @State private var locationTask: Task<Void, Never>?

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedCoordinate != nil &&
        endTime > startTime
    }

    var body: some View {
        NavigationStack {
            Form {
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

                Section("Event") {
                    TextField("Food title", text: $title)
                    TextField("Event details", text: $details, axis: .vertical)
                        .lineLimit(3...6)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    DatePicker("Start time", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End time", selection: $endTime, displayedComponents: .hourAndMinute)
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
            photos: Array(photos.prefix(3))
        ))
        dismiss()
    }
}
