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
                Section {
                    HStack(spacing: 14) {
                        BackpropMark(size: 44)
                            .padding(8)
                            .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entitlements.isPro ? "Backprop Pro" : "Backprop Free").font(.headline)
                            Text(entitlements.isPro ? "Every lesson unlocked" : "Chapters 1–2 of every track")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if entitlements.isPro {
                            Image(systemName: "checkmark.seal.fill").foregroundStyle(Color.accentColor).font(.title2)
                        }
                    }
                    .padding(.vertical, 4)
                    if !entitlements.isPro {
                        Button { showPaywall = true } label: {
                            Label("Upgrade to Pro", systemImage: "arrow.up.circle.fill")
                                .font(.headline)
                        }
                    }
                }

                Section("Subscription") {
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
