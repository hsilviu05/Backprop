import Foundation
import Observation
import OSLog
import RevenueCat

/// Single source of truth for whether the user has Backprop Pro.
@MainActor
@Observable
final class EntitlementStore {
    let isPurchasesConfigured: Bool
    private(set) var isPro = false
    /// False until the first CustomerInfo arrives, so the UI can avoid flashing locks.
    private(set) var hasLoaded = false
    private(set) var lastError: String?

    private let logger = Logger(subsystem: "Backprop", category: "Entitlements")

    init(isPurchasesConfigured: Bool) {
        self.isPurchasesConfigured = isPurchasesConfigured
        if !isPurchasesConfigured { hasLoaded = true }
    }

    /// Long-lived: call from a `.task` on the root view. Ends when the task is cancelled.
    func observe() async {
        guard isPurchasesConfigured else { return }
        do {
            apply(try await Purchases.shared.customerInfo())
        } catch {
            // Offline on first launch: keep free access, the stream will update us later.
            logger.error("customerInfo failed: \(error.localizedDescription, privacy: .public)")
            lastError = error.localizedDescription
            hasLoaded = true
        }
        for await info in Purchases.shared.customerInfoStream {
            apply(info)
        }
    }

    func apply(_ info: CustomerInfo) {
        isPro = Self.hasPro(info)
        hasLoaded = true
        lastError = nil
    }

    func restore() async -> Result<Bool, Error> {
        guard isPurchasesConfigured else { return .failure(PurchasesNotConfigured()) }
        do {
            let info = try await Purchases.shared.restorePurchases()
            apply(info)
            return .success(isPro)
        } catch {
            return .failure(error)
        }
    }

    nonisolated static func hasPro(_ info: CustomerInfo) -> Bool {
        info.entitlements[AppConfig.entitlementID]?.isActive == true
    }
}

struct PurchasesNotConfigured: LocalizedError {
    var errorDescription: String? { "Purchases aren't available in this build." }
}
