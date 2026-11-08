# Backprop setup: Mac, App Store Connect, RevenueCat

Do these in order. Steps marked **(blocks sandbox purchases)** must be done before any purchase works, even in testing.

## 0. On your Mac (≈15 min)

1. Install Xcode 16 or newer, and XcodeGen: `brew install xcodegen` (MIT license, build-time only, nothing ships in the app).
2. `cp Config/Secrets.example.xcconfig Config/Secrets.xcconfig` and fill in:
   - `BACKPROP_BUNDLE_ID`: the bundle ID you register in step 1.2 (e.g. `com.silviu.backprop`).
   - `BACKPROP_TEAM_ID`: developer.apple.com > Account > Membership details.
   - `REVENUECAT_API_KEY`: the **public** Apple key from RevenueCat (starts with `appl_`). Never an `sk_` secret key.
   - `BACKPROP_PRIVACY_URL`: your hosted privacy policy (keep the `https:/$()/` trick).
3. `xcodegen generate`, then open `Backprop.xcodeproj`.
4. Add a 1024×1024 app icon to `Backprop/Resources/Assets.xcassets/AppIcon` (uploads are rejected without one).
5. Run the tests (⌘U), then run on a device.

## 1. App Store Connect + Developer portal

### 1.1 Agreements **(blocks sandbox purchases)**
- App Store Connect > **Business** (Agreements, Tax, and Banking): accept the **Paid Apps** agreement, add bank account and tax forms. Status must be **Active**.
- Enroll in the **App Store Small Business Program** (developer.apple.com/app-store/small-business-program) for the 15% rate.

### 1.2 Bundle ID
- developer.apple.com > Certificates, Identifiers & Profiles > Identifiers > **+** > App IDs > App.
- Explicit bundle ID, same as `BACKPROP_BUNDLE_ID`. In-App Purchase capability is on by default.

### 1.3 App record
- App Store Connect > Apps > **+** > New App: iOS, name `Backprop: Learn ML & AI`, primary language English (U.S.), your bundle ID, any SKU (e.g. `backprop-ios`).
- If the name is taken, you'll find out here. Do the trademark check before you invest in branding.

### 1.4 Subscriptions
App > Monetization > **Subscriptions**:
1. Create subscription group, reference name **`backprop_pro`**. Add a group localization (display name e.g. "Backprop Pro").
2. Add subscription **`backprop_pro_yearly`**: duration 1 year, price **$79.99** (USA base, let Apple equalize other storefronts), localization (display name "Backprop Pro Yearly", description), review screenshot (screenshot of the paywall), review notes.
3. Add subscription **`backprop_pro_monthly`**: 1 month, **$12.99**, same fields.
4. Put **yearly at a higher level** than monthly in the group (level 1 = yearly), so monthly→yearly is an upgrade.
5. Introductory offers:
   - yearly: **Free**, 1 week (7-day trial), all territories.
   - monthly: **Pay as you go**, $4.99, 1 period of 1 month.
6. Leave status "Ready to Submit". **The first subscriptions must be submitted together with an app version**: on the version page, add them under "In-App Purchases and Subscriptions".

Offers for later (no need for v1.0 submission): promotional offer yearly $39.99 (paywall-dismiss), retention monthly $6.49 × 3 (Customer Center), win-back yearly $49.99, offer codes for the founding-member launch.

### 1.5 Keys for RevenueCat
- Users and Access > **Integrations > In-App Purchase** > generate key. Download the `.p8` (only downloadable once). Note the **Key ID** and **Issuer ID**.
- Users and Access > **Integrations > App Store Connect API** > Team Keys > generate a key with **App Manager** access. Download the `.p8`, note Key ID and Issuer ID. (RevenueCat uses this to import products and prices.)

### 1.6 Server notifications (after RevenueCat step 2.2)
- App > **App Information** > App Store Server Notifications: paste RevenueCat's URL into **both** Production and Sandbox, Version 2.

### 1.7 Sandbox tester
- Users and Access > **Sandbox** > Test Accounts > **+**. Use an email that isn't an existing Apple Account.
- On the test iPhone: sign in to the sandbox account under the App Store / Developer section of Settings (exact location varies by iOS version) when the purchase sheet asks.

### 1.8 Store listing (needed for submission, not for testing)
- App Privacy: declare **Purchases** (purchase history) and **Identifiers** (user ID / device ID) used for App Functionality, linked to user: No (anonymous IDs), tracking: No. Re-check if you add analytics.
- Privacy Policy URL (required). Terms: either Apple's standard EULA (add a link to it in the description) or a custom EULA.
- Age rating questionnaire, category Education, price Free, screenshots (6.9" iPhone), subtitle `Data science in 5-min lessons`, description, keywords, support URL.
- Export compliance is already answered in Info.plist (`ITSAppUsesNonExemptEncryption = NO`).

## 2. RevenueCat dashboard

### 2.1 Project
- app.revenuecat.com > **Create project** "Backprop".

### 2.2 App
- Project > **Apps & providers** > add **App Store** app, bundle ID = yours.
- Upload the **In-App Purchase key** (.p8 + Key ID + Issuer ID from 1.5).
- Upload the **App Store Connect API key** (.p8 + Key ID + Issuer ID + vendor number if asked).
- Copy the **Apple Server to Server notification URL** shown there into App Store Connect (step 1.6).

### 2.3 Products
- **Product catalog > Products**: import (or add) `backprop_pro_yearly` and `backprop_pro_monthly`.

### 2.4 Entitlement
- Product catalog > **Entitlements** > New: identifier **`pro`** (exactly; the app checks this string). Attach both products.

### 2.5 Offering
- Product catalog > **Offerings** > New: identifier **`default`**, mark as **Current**.
- Packages: **Annual** (`$rc_annual`) → `backprop_pro_yearly`; **Monthly** (`$rc_monthly`) → `backprop_pro_monthly`.

### 2.6 Paywall
- **Paywalls** > create a paywall for the `default` offering. The app shows whatever paywall is attached to the current offering, so no app update is needed to change it.
- Must show (guideline 3.1.2): price per period, trial length and what it renews at, auto-renew wording, **Restore purchases**, links to **Terms** and **Privacy Policy**, and a visible **close button**.
- Select the Annual package by default.

### 2.7 Customer Center
- **Customer Center** > configure and enable. Add the retention offer later, once the promotional offer exists in App Store Connect.

### 2.8 API key
- Project settings > **API keys** > copy the **Apple public SDK key** (`appl_...`) into `Config/Secrets.xcconfig`.

## 3. Test before submitting
Run on a real device with the sandbox account: purchase yearly (trial starts), purchase monthly, upgrade monthly→yearly, restore on a reinstall, open Settings > Manage subscription (Customer Center), confirm Pro chapters unlock and the soft paywall appears after the last free lesson. Check the customer shows up in RevenueCat > Customers. Then archive, upload to TestFlight, and repeat the purchase test there.
