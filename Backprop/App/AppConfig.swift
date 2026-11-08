import Foundation

/// Build-time configuration read from Info.plist (values come from Config/*.xcconfig).
struct AppConfig: Sendable {
    let revenueCatAPIKey: String?
    let termsURL: URL?
    let privacyURL: URL?

    static let entitlementID = "pro"

    static let current = AppConfig(bundle: .main)

    init(bundle: Bundle) {
        revenueCatAPIKey = Self.nonEmptyString(bundle, "RevenueCatAPIKey")
        termsURL = Self.nonEmptyString(bundle, "BackpropTermsURL").flatMap(Self.httpsURL)
        privacyURL = Self.nonEmptyString(bundle, "BackpropPrivacyURL").flatMap(Self.httpsURL)
    }

    init(revenueCatAPIKey: String?, termsURL: URL?, privacyURL: URL?) {
        self.revenueCatAPIKey = revenueCatAPIKey
        self.termsURL = termsURL
        self.privacyURL = privacyURL
    }

    private static func nonEmptyString(_ bundle: Bundle, _ key: String) -> String? {
        guard let raw = bundle.object(forInfoDictionaryKey: key) as? String else { return nil }
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        // An unset build setting can leave the literal "$(NAME)" in the plist.
        return value.isEmpty || value.hasPrefix("$(") ? nil : value
    }

    static func httpsURL(_ string: String) -> URL? {
        guard let url = URL(string: string), url.scheme == "https", url.host != nil else { return nil }
        return url
    }

    /// The public Apple SDK key starts with "appl_". Secret keys must never ship in the app.
    static func isValidPublicAppleKey(_ key: String?) -> Bool {
        guard let key else { return false }
        return key.hasPrefix("appl_") && key.count > 5
    }
}
