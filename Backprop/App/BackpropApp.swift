import OSLog
import RevenueCat
import SwiftData
import SwiftUI

@main
struct BackpropApp: App {
    @State private var entitlements: EntitlementStore
    @State private var content: ContentLibrary
    private let modelContainer: ModelContainer

    init() {
        let config = AppConfig.current
        let configured = PurchasesBootstrap.configure(apiKey: config.revenueCatAPIKey)
        _entitlements = State(initialValue: EntitlementStore(isPurchasesConfigured: configured))
        _content = State(initialValue: ContentLibrary.loadBundled())

        do {
            modelContainer = try ModelContainer(for: LessonCompletion.self, StudyDay.self)
        } catch {
            // The schema is static, so this only fails if the store file is unreadable.
            fatalError("Could not open progress store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(entitlements)
                .environment(content)
                .task { await entitlements.observe() }
        }
        .modelContainer(modelContainer)
    }
}

enum PurchasesBootstrap {
    /// Configures RevenueCat once. Returns false when no valid public key is set,
    /// so the app still runs (everything free stays usable) instead of crashing.
    @discardableResult
    static func configure(apiKey: String?) -> Bool {
        guard AppConfig.isValidPublicAppleKey(apiKey), let apiKey else {
            Logger(subsystem: "Backprop", category: "Purchases")
                .error("REVENUECAT_API_KEY missing or not a public Apple key (appl_...). See Config/Secrets.example.xcconfig.")
            return false
        }
        #if DEBUG
        Purchases.logLevel = .debug
        #else
        Purchases.logLevel = .warn
        #endif
        if !Purchases.isConfigured {
            Purchases.configure(withAPIKey: apiKey)
        }
        return true
    }
}
