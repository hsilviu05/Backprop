import SwiftUI

struct SettingsView: View {
    @Environment(EntitlementStore.self) private var entitlements
    @Environment(\.openURL) private var openURL
    @State private var showPaywall = false
    @State private var showCustomerCenter = false
    @State private var isRestoring = false
    @State private var restoreMessage: String?

    private let config = AppConfig.current

    var body: some View {
        NavigationStack {
            List {
                Section("Subscription") {
                    if entitlements.isPro {
                        Label("Backprop Pro is active", systemImage: "checkmark.seal.fill")
                    } else {
                        Button("Upgrade to Pro") { showPaywall = true }
                    }
                    Button("Manage subscription") { showCustomerCenter = true }
                    Button {
                        Task { await restore() }
                    } label: {
                        HStack {
                            Text("Restore purchases")
                            if isRestoring { Spacer(); ProgressView() }
                        }
                    }
                    .disabled(isRestoring)
                }

                Section("Legal") {
                    if let terms = config.termsURL {
                        Button("Terms of Use") { openURL(terms) }
                    }
                    if let privacy = config.privacyURL {
                        Button("Privacy Policy") { openURL(privacy) }
                    }
                }

                Section {
                    LabeledContent("Version", value: Self.versionString)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallSheet() }
            .sheet(isPresented: $showCustomerCenter) { CustomerCenterSheet() }
            .alert("Restore purchases", isPresented: Binding(
                get: { restoreMessage != nil }, set: { if !$0 { restoreMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(restoreMessage ?? "")
            }
        }
    }

    private func restore() async {
        isRestoring = true
        defer { isRestoring = false }
        switch await entitlements.restore() {
        case .success(true): restoreMessage = "Backprop Pro has been restored."
        case .success(false): restoreMessage = "No active subscription was found for this Apple Account."
        case .failure(let error): restoreMessage = error.localizedDescription
        }
    }

    private static var versionString: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }
}
