import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings

    private var countryName: String {
        settings.myCountry.isEmpty ? "Unknown"
            : (Locale.current.localizedString(forRegionCode: settings.myCountry) ?? settings.myCountry)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(isOn: $settings.onlyMyCountry) {
                        VStack(alignment: .leading) {
                            Text("Only my country")
                            Text(countryName).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Toggle("Limit by distance", isOn: $settings.limitDistance)
                    if settings.limitDistance {
                        VStack(alignment: .leading) {
                            Text("Within \(Int(settings.maxDistanceKm)) km")
                                .font(.subheadline)
                            Slider(value: $settings.maxDistanceKm, in: 1...50, step: 1)
                        }
                    }
                } header: {
                    Text("Where to show food")
                } footer: {
                    Text("Distance filtering uses your current location. Subscribed recurring giveaways are always shown.")
                }

                Section("Subscriptions") {
                    if settings.subscribedIDs.isEmpty {
                        Text("No subscriptions yet. Open a recurring giveaway and tap Subscribe.")
                            .foregroundStyle(.secondary)
                    } else {
                        Text("\(settings.subscribedIDs.count) recurring giveaway\(settings.subscribedIDs.count == 1 ? "" : "s") subscribed")
                        Button("Clear all subscriptions", role: .destructive) {
                            settings.subscribedIDs = []
                        }
                    }
                }

                Section("About FreeFood") {
                    Label("FreeFood helps communities reduce food waste by sharing real, available free food. Please don't post fictitious events.", systemImage: "leaf.fill")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}
