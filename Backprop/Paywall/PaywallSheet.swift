import RevenueCat
import RevenueCatUI
import SwiftUI

/// Presents the in-app paywall. Restore, Terms and Privacy are on the paywall itself (guideline 3.1.2).
struct PaywallSheet: View {
    @Environment(EntitlementStore.self) private var entitlements
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if entitlements.isPurchasesConfigured {
            BackpropPaywallView { dismiss() }
        } else {
            NavigationStack {
                ContentUnavailableView(
                    "Purchases unavailable",
                    systemImage: "cart.badge.questionmark",
                    description: Text("This build has no RevenueCat key configured.")
                )
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                    }
                }
            }
        }
    }
}

/// RevenueCat Customer Center: manage, cancel, refund request, retention offers.
struct CustomerCenterSheet: View {
    @Environment(EntitlementStore.self) private var entitlements

    var body: some View {
        if entitlements.isPurchasesConfigured {
            CustomerCenterView()
        } else {
            ContentUnavailableView("Purchases unavailable", systemImage: "cart.badge.questionmark")
        }
    }
}
