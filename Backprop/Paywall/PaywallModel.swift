import Foundation
import Observation
import RevenueCat

/// Loads the current RevenueCat offering and runs purchases for the in-app paywall.
@MainActor
@Observable
final class PaywallModel {
    enum LoadState: Equatable { case loading, loaded, failed(String) }

    private(set) var state: LoadState = .loading
    private(set) var annual: Package?
    private(set) var monthly: Package?
    private(set) var eligibleForIntro: Set<String> = []
    var selected: Package?
    private(set) var isPurchasing = false
    var errorMessage: String?

    var packages: [Package] { [annual, monthly].compactMap { $0 } }

    func load() async {
        state = .loading
        do {
            guard let offering = try await Purchases.shared.offerings().current else {
                state = .failed("No subscription options are available right now.")
                return
            }
            annual = offering.annual
            monthly = offering.monthly
            guard !packages.isEmpty else {
                state = .failed("No subscription options are available right now.")
                return
            }
            if selected == nil { selected = annual ?? monthly }
            let eligibility = await Purchases.shared.checkTrialOrIntroDiscountEligibility(packages: packages)
            eligibleForIntro = Set(eligibility.filter { $0.value.status == .eligible }.map { $0.key.identifier })
            state = .loaded
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func isEligibleForIntro(_ package: Package) -> Bool {
        package.storeProduct.introductoryDiscount != nil && eligibleForIntro.contains(package.identifier)
    }

    /// Returns the new CustomerInfo, or nil when the user cancelled or the purchase failed.
    func purchase() async -> CustomerInfo? {
        guard let package = selected, !isPurchasing else { return nil }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await Purchases.shared.purchase(package: package)
            return result.userCancelled ? nil : result.customerInfo
        } catch {
            if !Self.isCancellation(error) { errorMessage = error.localizedDescription }
            return nil
        }
    }

    private static func isCancellation(_ error: Error) -> Bool {
        if let code = error as? ErrorCode { return code == .purchaseCancelledError }
        return (error as NSError).code == ErrorCode.purchaseCancelledError.rawValue
            && (error as NSError).domain == ErrorCode.errorDomain
    }

    /// Yearly savings vs. paying monthly for 12 months, e.g. 49. Nil if it can't be computed.
    var annualSavingsPercent: Int? {
        guard let annual, let monthly else { return nil }
        let yearOfMonthly = monthly.storeProduct.price * 12
        guard yearOfMonthly > 0 else { return nil }
        let ratio = NSDecimalNumber(decimal: annual.storeProduct.price / yearOfMonthly).doubleValue
        let percent = Int(((1 - ratio) * 100).rounded(.down))
        return percent > 0 ? percent : nil
    }
}

enum PeriodText {
    /// "1 week", "7 days", "1 month", "1 year".
    static func describe(_ period: SubscriptionPeriod) -> String {
        let unit: String
        switch period.unit {
        case .day: unit = "day"
        case .week: unit = "week"
        case .month: unit = "month"
        case .year: unit = "year"
        @unknown default: unit = "period"
        }
        return "\(period.value) \(unit)\(period.value == 1 ? "" : "s")"
    }

    /// "year" / "month" for "per" phrasing.
    static func unit(_ period: SubscriptionPeriod?) -> String {
        guard let period else { return "period" }
        let base: String
        switch period.unit {
        case .day: base = "day"
        case .week: base = "week"
        case .month: base = "month"
        case .year: base = "year"
        @unknown default: base = "period"
        }
        return period.value == 1 ? base : "\(period.value) \(base)s"
    }

    /// Short offer label: "7 days free", "$4.99 for the first month".
    static func offer(_ discount: StoreProductDiscount) -> String {
        switch discount.paymentMode {
        case .freeTrial:
            let p = discount.subscriptionPeriod
            if p.unit == .week { return "\(p.value * 7 * discount.numberOfPeriods)-day free trial" }
            return "\(describe(p)) free"
        case .payAsYouGo:
            let count = discount.numberOfPeriods
            return count == 1
                ? "\(discount.localizedPriceString) for the first \(unit(discount.subscriptionPeriod))"
                : "\(discount.localizedPriceString)/\(unit(discount.subscriptionPeriod)) for \(count) \(unit(discount.subscriptionPeriod))s"
        case .payUpFront:
            return "\(discount.localizedPriceString) for the first \(describe(discount.subscriptionPeriod))"
        @unknown default:
            return "Introductory offer"
        }
    }
}
