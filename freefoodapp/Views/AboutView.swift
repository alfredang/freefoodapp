import SwiftUI

/// Static "About" screen: app blurb, developer, data source, and version.
/// Mirrors the grouped-card layout used across Tertiary Infotech apps.
struct AboutView: View {
    private let developerName = "Tertiary Infotech Academy Pte Ltd"
    private let developerSite = "tertiaryinfotech.com"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    appCard
                    developerSection
                    dataSection
                    versionCard
                }
                .padding()
            }
            .navigationTitle("About")
        }
    }

    private var appCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("FreeFood: Share Leftovers")
                .font(.title2.bold())
            Text("Post and discover free leftover food nearby. Create a listing with photos, location, date, and a pickup time window; browse a searchable feed sorted by what's closest to you; and view everything on a map. Everything stays on your device — no account, no sign-in.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
    }

    private var developerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Developer")
                .font(.headline)
                .foregroundStyle(.secondary)
            VStack(spacing: 0) {
                Label(developerName, systemImage: "building.2.fill")
                    .labelStyle(.titleAndIcon)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                Divider().padding(.leading)
                Link(destination: URL(string: "https://\(developerSite)")!) {
                    Label(developerSite, systemImage: "globe")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
            .background(.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
            .tint(.green)
        }
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Data")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("All listings are stored locally on your device. There is no backend and no user account, and listings automatically expire 7 days after they are posted.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private var versionCard: some View {
        HStack {
            Text("Version")
            Spacer()
            Text(appVersion).foregroundStyle(.secondary)
        }
        .padding()
        .background(.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}
