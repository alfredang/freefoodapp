import SwiftUI

/// Lets users send a feature request or bug report straight to the developer's
/// WhatsApp. We only open a pre-filled `wa.me` link — nothing is stored or sent
/// anywhere else, which keeps the app's "no backend" model intact.
struct FeedbackView: View {
    /// Developer WhatsApp number in international format, digits only.
    private let whatsAppNumber = "6588666375"

    private enum Kind: String, CaseIterable, Identifiable {
        case feature = "New feature"
        case bug = "Bug report"
        var id: String { rawValue }
    }

    @State private var kind: Kind = .feature
    @State private var message = ""
    @State private var showCannotOpen = false
    @FocusState private var editorFocused: Bool

    private var canSend: Bool {
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $kind) {
                        ForEach(Kind.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("What's on your mind?")
                } footer: {
                    Text("Tell us about a feature you'd love, or a bug you ran into. Sends via WhatsApp to the FreeFood team.")
                }

                Section(kind == .feature ? "Describe the feature" : "Describe the bug") {
                    TextEditor(text: $message)
                        .frame(minHeight: 140)
                        .focused($editorFocused)
                        .overlay(alignment: .topLeading) {
                            if message.isEmpty {
                                Text(kind == .feature
                                     ? "e.g. Let me filter by food type…"
                                     : "e.g. The map didn't show my listing…")
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 8)
                                    .allowsHitTesting(false)
                            }
                        }
                }

                Section {
                    Button {
                        send()
                    } label: {
                        Label("Send via WhatsApp", systemImage: "paperplane.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(!canSend)
                }
            }
            .navigationTitle("Feedback")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { editorFocused = false }
                }
            }
            .alert("Couldn't open WhatsApp", isPresented: $showCannotOpen) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Make sure WhatsApp is installed, then try again.")
            }
        }
    }

    private func send() {
        let body = "FreeFood \(kind.rawValue):\n\(message.trimmingCharacters(in: .whitespacesAndNewlines))"
        let encoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "https://wa.me/\(whatsAppNumber)?text=\(encoded)") else {
            showCannotOpen = true
            return
        }
        UIApplication.shared.open(url) { success in
            if !success { showCannotOpen = true }
        }
    }
}
