import RevenueCat
import RevenueCatUI
import SwiftUI

/// RevenueCat dashboard paywall for the current offering ("default").
/// Price, trial terms, Restore and the Terms/Privacy links are configured on the paywall in RevenueCat.
struct PaywallSheet: View {
    @Environment(EntitlementStore.self) private var entitlements
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if entitlements.isPurchasesConfigured {
            PaywallView(displayCloseButton: true)
                .onPurchaseCompleted { info in
                    entitlements.apply(info)
                    dismiss()
                }
                .onRestoreCompleted { info in
                    entitlements.apply(info)
                    if EntitlementStore.hasPro(info) { dismiss() }
                }
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
