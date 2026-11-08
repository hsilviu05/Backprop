import RevenueCat
import SwiftUI

/// In-app paywall using the app's own design. Prices, trials and intro offers
/// come live from the current RevenueCat offering ("default").
struct BackpropPaywallView: View {
    let onFinished: () -> Void

    @Environment(EntitlementStore.self) private var entitlements
    @Environment(\.openURL) private var openURL
    @State private var model = PaywallModel()
    @State private var isRestoring = false
    @State private var restoreMessage: String?

    private let config = AppConfig.current

    private static let features: [(icon: String, title: String, detail: String, tint: Color)] = [
        ("books.vertical.fill", "Every chapter, all 4 tracks", "Stats, classic ML, neural networks, modern AI", .indigo),
        ("hand.draw.fill", "Hands-on simulations", "Drag data, tune learning rates, watch models learn", .teal),
        ("calendar.badge.plus", "New lessons as they launch", "The library keeps growing", .orange),
        ("flame.fill", "Build a daily habit", "Streaks and XP keep you going", .pink),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 10) {
                    BackpropMark(size: 44, animated: true)
                        .padding(12)
                        .cardSurface(cornerRadius: 20)
                    Text("Unlock all of Backprop")
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                    Text("Understand machine learning, one 5‑minute lesson at a time.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 28)
                .appearAnimation()

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(Self.features.enumerated()), id: \.offset) { index, feature in
                        HStack(spacing: 12) {
                            IconTile(systemImage: feature.icon, tint: feature.tint, size: 30)
                            Text(feature.title).font(.subheadline.weight(.semibold))
                            Spacer(minLength: 0)
                        }
                        .accessibilityHint(feature.detail)
                        .appearAnimation(delay: 0.05 + 0.04 * Double(index))
                    }
                }
                .padding(Theme.padding)
                .cardSurface()

                packagesSection
            }
            .padding(.horizontal, Theme.padding)
            .padding(.bottom, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .screenBackground()
        .overlay(alignment: .topTrailing) { closeButton }
        .safeAreaInset(edge: .bottom, spacing: 0) { purchaseBar }
        .task { await model.load() }
        .alert("Purchase failed", isPresented: Binding(
            get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(model.errorMessage ?? "")
        }
        .alert("Restore purchases", isPresented: Binding(
            get: { restoreMessage != nil }, set: { if !$0 { restoreMessage = nil } }
        )) {
            Button("OK", role: .cancel) {
                if entitlements.isPro { onFinished() }
            }
        } message: {
            Text(restoreMessage ?? "")
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var packagesSection: some View {
        switch model.state {
        case .loading:
            ProgressView().frame(maxWidth: .infinity, minHeight: 140)
        case .failed(let message):
            VStack(spacing: 12) {
                Text(message).font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center)
                Button("Try again") { Task { await model.load() } }
                    .secondaryButtonStyle()
            }
            .frame(maxWidth: .infinity)
            .padding(Theme.padding)
        case .loaded:
            VStack(spacing: 12) {
                ForEach(model.packages, id: \.identifier) { package in
                    PackageOption(
                        package: package,
                        isSelected: model.selected?.identifier == package.identifier,
                        offerText: model.isEligibleForIntro(package)
                            ? package.storeProduct.introductoryDiscount.map(PeriodText.offer)
                            : nil,
                        badge: package.packageType == .annual
                            ? model.annualSavingsPercent.map { "Save \($0)%" }
                            : nil
                    ) {
                        withAnimation(Theme.spring) { model.selected = package }
                    }
                }
            }
            .sensoryFeedback(.selection, trigger: model.selected?.identifier)
        }
    }

    private var closeButton: some View {
        Button(action: onFinished) {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 34, height: 34)
                .cardSurface(cornerRadius: 17)
        }
        .buttonStyle(.plain)
        .padding(.trailing, Theme.padding)
        .padding(.top, 12)
        .accessibilityLabel("Close")
    }

    private var purchaseBar: some View {
        VStack(spacing: 10) {
            Button {
                Task {
                    if let info = await model.purchase() {
                        entitlements.apply(info)
                        if EntitlementStore.hasPro(info) { onFinished() }
                    }
                }
            } label: {
                ZStack {
                    Text(ctaTitle).font(.headline).opacity(model.isPurchasing ? 0 : 1)
                    if model.isPurchasing { ProgressView() }
                }
                .frame(maxWidth: .infinity)
            }
            .primaryButtonStyle()
            .disabled(model.selected == nil || model.isPurchasing || model.state != .loaded)

            Text(termsText)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 16) {
                Button(isRestoring ? "Restoring…" : "Restore purchases") { Task { await restore() } }
                    .disabled(isRestoring)
                if let terms = config.termsURL {
                    Button("Terms of Use") { openURL(terms) }
                }
                if let privacy = config.privacyURL {
                    Button("Privacy Policy") { openURL(privacy) }
                }
            }
            .font(.caption.weight(.medium))
            .tint(.secondary)
        }
        .padding(.horizontal, Theme.padding)
        .padding(.top, 20)
        .padding(.bottom, 8)
        // Fades into the page instead of a hard-edged bar.
        .background {
            LinearGradient(
                stops: [
                    .init(color: Color(.systemGroupedBackground).opacity(0), location: 0),
                    .init(color: Color(.systemGroupedBackground), location: 0.25),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Copy

    private var ctaTitle: String {
        guard let package = model.selected else { return "Continue" }
        if model.isEligibleForIntro(package), package.storeProduct.introductoryDiscount?.paymentMode == .freeTrial {
            return "Start free trial"
        }
        return "Continue"
    }

    /// Auto-renew disclosure required by App Store guideline 3.1.2.
    private var termsText: String {
        guard let package = model.selected else {
            return "Subscriptions renew automatically. Cancel anytime in Settings."
        }
        let product = package.storeProduct
        let renewal = "\(product.localizedPriceString)/\(PeriodText.unit(product.subscriptionPeriod))"
        let lead: String
        if model.isEligibleForIntro(package), let discount = product.introductoryDiscount {
            lead = "\(PeriodText.offer(discount)), then \(renewal)."
        } else {
            lead = "\(renewal)."
        }
        return "\(lead) Renews automatically unless cancelled at least 24 hours before the end of the current period. Manage or cancel anytime in your Apple Account settings."
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
}

private struct PackageOption: View {
    let package: Package
    let isSelected: Bool
    let offerText: String?
    let badge: String?
    let onSelect: () -> Void

    private var title: String {
        switch package.packageType {
        case .annual: "Yearly"
        case .monthly: "Monthly"
        default: package.storeProduct.localizedTitle
        }
    }

    var body: some View {
        let product = package.storeProduct
        Button(action: onSelect) {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary.opacity(0.5))
                    .contentTransition(.symbolEffect(.replace))
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(title).font(.headline)
                        if let badge {
                            Text(badge)
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .foregroundStyle(.white)
                                .background(Color.accentColor, in: Capsule())
                        }
                    }
                    if let offerText {
                        Text(offerText).font(.subheadline.weight(.medium)).foregroundStyle(Color.accentColor)
                    }
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(product.localizedPriceString)/\(PeriodText.unit(product.subscriptionPeriod))")
                        .font(.headline.monospacedDigit())
                    if package.packageType == .annual, let perMonth = product.localizedPricePerMonth {
                        Text("\(perMonth)/month").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(Theme.padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .cardSurface(cornerRadius: Theme.smallCornerRadius + 4, tint: isSelected ? .accentColor : nil, interactive: true)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.smallCornerRadius + 4, style: .continuous)
                .strokeBorder(Color.accentColor, lineWidth: isSelected ? 2 : 0)
        )
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
