# Backprop 1.0.0 launch guide

One ordered list, from zero to "Submitted for Review". Do the steps in order: later steps need values from earlier ones.

> **Before you start:** this code has never been compiled (it was written without Xcode). Expect a few build fixes in Phase 4. Don't submit until Phases 4–6 pass.

**Rough timing:** Phases 1–3 take ~2 hours. The bank and tax review in Phase 1 can take Apple up to a day or two, and sandbox purchases may not work until it's done. Phases 4–6 take a few hours. Apple's review usually takes 1–3 days, plus about a day more for each rejection.

You'll collect these values as you go. Keep them somewhere safe and never commit them:

| Value | From | Goes into |
|---|---|---|
| Bundle ID | Phase 1.3 | `Config/Secrets.xcconfig`, RevenueCat |
| Team ID | Phase 1.2 | `Config/Secrets.xcconfig` |
| IAP key `.p8` + Key ID + Issuer ID | Phase 2.4 | RevenueCat |
| App Store Connect API key `.p8` + Key ID + Issuer ID | Phase 2.4 | RevenueCat |
| RevenueCat server notification URL | Phase 3.2 | App Store Connect |
| RevenueCat public key `appl_…` | Phase 3.7 | `Config/Secrets.xcconfig` |
| Privacy policy URL: `https://hsilviu05.github.io/Backprop/legal/privacy.html` | Phase 1.5 | `Config/Secrets.xcconfig`, App Store Connect |

---

## Phase 1: Accounts and legal (start first, Apple can be slow)

1. **Apple Developer Program** membership is active (developer.apple.com/account).
2. Note your **Team ID**: developer.apple.com > Account > Membership details.
3. **Register the bundle ID**: Certificates, Identifiers & Profiles > Identifiers > **+** > App IDs > App > Explicit, e.g. `com.silviu.backprop`. In-App Purchase is on by default.
4. **Paid Apps agreement**: App Store Connect > **Business** > accept the Paid Apps agreement, add your bank account and fill in the tax forms. Status must become **Active**, or purchases fail, even in sandbox.
5. **Privacy policy and support pages**: both are in `docs/` and served by GitHub Pages (Settings > Pages > branch `main`, folder `/docs`). Privacy: `https://hsilviu05.github.io/Backprop/legal/privacy.html`. Support: `https://hsilviu05.github.io/Backprop/support.html`. Open both in a browser to check they load before you submit.
6. **Small Business Program**: apply at developer.apple.com/app-store/small-business-program to pay 15% instead of 30%.
7. **Name check**: search the App Store, USPTO and EUIPO for "Backprop". Phase 2.1 will tell you if the App Store name is taken.

## Phase 2: App Store Connect

1. **Create the app**: Apps > **+** > New App > iOS. Name `Backprop: Learn ML & AI`, primary language English (U.S.), the bundle ID from 1.3, SKU `backprop-ios`, full access.
2. **App Information**: fill in every field from section 1 of [`APP_STORE_METADATA.md`](APP_STORE_METADATA.md) (category, content rights, age rating).
3. **Subscriptions**: Monetization > Subscriptions.
   1. Create a subscription group with reference name **`backprop_pro`**. Add a group localization: display name `Backprop Pro`.
   2. **+** subscription: reference name `Pro Yearly`, product ID **`backprop_pro_yearly`**, duration **1 year**, price **$79.99** (US base, let Apple set the other countries). Localization: display name and description from section 4 of [`APP_STORE_METADATA.md`](APP_STORE_METADATA.md). Review screenshot: a screenshot of the paywall (you can add it after Phase 4).
   3. **+** subscription: reference name `Pro Monthly`, product ID **`backprop_pro_monthly`**, **1 month**, **$12.99**, localization from the same section.
   4. Levels: drag **yearly to level 1** and monthly to level 2. That makes monthly→yearly an upgrade.
   5. **Introductory offers**: yearly gets **Free, 1 week**, all countries. Monthly gets **Pay as you go, $4.99 for 1 month**.
   6. Leave both at "Ready to Submit". They go to review with the app version in Phase 7.
4. **Keys**: Users and Access > **Integrations**.
   - **In-App Purchase** > generate a key. Download the `.p8` (you can only download it once) and note the Key ID and Issuer ID.
   - **App Store Connect API** > Team Keys > generate a key with role **App Manager**. Download the `.p8` and note the Key ID and Issuer ID.
5. **Sandbox tester**: Users and Access > **Sandbox** > Test Accounts > **+**. Use a new email address that isn't an Apple Account yet (Gmail `+` aliases work).

## Phase 3: RevenueCat

1. app.revenuecat.com > **Create project** "Backprop".
2. **Apps & providers** > **+ App Store** app. Enter the bundle ID. Upload the **In-App Purchase key** (`.p8`, Key ID, Issuer ID) and the **App Store Connect API key**. Copy the **Apple Server to Server notification URL** that RevenueCat shows.
3. Back in **App Store Connect** > your app > App Information > **App Store Server Notifications**: paste that URL into both **Production** and **Sandbox**, version **2**.
4. **Product catalog > Products**: import `backprop_pro_yearly` and `backprop_pro_monthly`.
5. **Entitlements** > New: identifier **`pro`**. It must be exactly `pro`, because the app checks this string. Attach both products.
6. **Offerings** > New: identifier **`default`**, set it as **Current**. Add two packages: **Annual** (`$rc_annual`) → `backprop_pro_yearly`, and **Monthly** (`$rc_monthly`) → `backprop_pro_monthly`.
7. **Paywalls** > create a paywall for `default`. Apple's guideline 3.1.2 requires all of these:
   - price per period, and the yearly price per month as a secondary line
   - "7-day free trial, then $79.99/year", worded like that
   - text saying the subscription renews automatically unless cancelled at least 24 hours before the period ends
   - a **Restore purchases** button
   - links to **Terms of Use** (Apple's standard EULA: `https://www.apple.com/legal/internet-services/itunes/dev/stdeula/`) and your **Privacy Policy**
   - a visible **close button**
   - Annual selected by default
8. **Customer Center**: turn it on with the default settings. Retention offers come later.
9. **API keys**: Project settings > API keys > copy the **Apple public key** (`appl_…`). Never use a secret `sk_…` key in the app.

## Phase 4: Build on your Mac

1. Install Xcode 16 or newer, then `brew install xcodegen` (MIT license, build-time tool only).
2. `git clone https://github.com/hsilviu05/Backprop && cd Backprop`, then check out the release branch (or `main` once PR #2 is merged).
3. `cp Config/Secrets.example.xcconfig Config/Secrets.xcconfig` and fill in the bundle ID, Team ID, the `appl_` key and the privacy URL. Keep the `https:/$()/` spelling.
4. Add a **1024×1024 PNG app icon** (no transparency) to `Backprop/Resources/Assets.xcassets/AppIcon`.
5. `xcodegen generate && open Backprop.xcodeproj`. Wait for Swift Package Manager to fetch RevenueCat.
6. **⌘B** to build. Fix any compile errors (or paste them into this thread and I'll fix them).
7. **⌘U** to run the tests. All of them must pass. `ContentTests` checks every lesson file.
8. Run on the simulator: go through onboarding, open a lesson, try both sims, finish a quiz, and check the streak and XP update.

## Phase 5: Sandbox purchase testing (real iPhone)

Run from Xcode on your iPhone with the **Debug** scheme. When the purchase sheet appears, sign in with the sandbox tester. Check each of these:

- [ ] The paywall loads with real prices (if it's blank, check Phases 2.3, 3.4–3.6 and the Paid Apps agreement)
- [ ] Buying yearly starts the trial, and Pro chapters unlock right away
- [ ] The customer shows up in RevenueCat > **Customers** with the `pro` entitlement
- [ ] Monthly purchase works on a fresh sandbox account
- [ ] Upgrading from monthly to yearly works
- [ ] After deleting and reinstalling the app, Settings > **Restore purchases** brings Pro back
- [ ] Settings > **Manage subscription** opens the Customer Center
- [ ] Finishing the last free lesson (end of chapter 2) shows the paywall for a free user
- [ ] Closing the paywall during onboarding still lets you use the free content (Apple checks this)
- [ ] Airplane mode: free lessons still work and the app doesn't crash

Sandbox renewals run fast (a year takes about an hour), so the trial expires quickly. That's expected.

## Phase 6: TestFlight

1. Xcode: choose **Any iOS Device**, then Product > **Archive** > Distribute App > **App Store Connect** > Upload.
2. Wait for processing (10–30 min). App Store Connect > TestFlight > install on your phone through the TestFlight app.
3. Repeat the Phase 5 purchase checks on the TestFlight build. TestFlight uses sandbox payments, so nothing is charged.
4. Optional but recommended: invite 5–20 friends as external testers for 2–3 days. External testing needs a short Beta App Review.

## Phase 7: Store listing and submit

Copy every field from [`APP_STORE_METADATA.md`](APP_STORE_METADATA.md). Each block is labeled with its screen and field and is checked against Apple's limits (`python3 docs/check_metadata.py`).

1. App Store tab > **1.0 Prepare for Submission**:
   - Screenshots: **6.9" iPhone** (1320×2868), 3 to 10 of them. Show onboarding, the 4 tracks, a lesson, the regression sim, the gradient descent sim, the Reading tab, streaks, and the paywall.
   - Promotional text, description, keywords, support URL, version **1.0.0** and copyright: section 2 of the metadata file.
   - Under **In-App Purchases and Subscriptions**, add **both** subscriptions. This is required for the first release.
   - Build: select the TestFlight build from Phase 6.
   - **App Review Information**: your contact details, no sign-in needed, and the review notes from the metadata file (they ask the reviewer to use a sandbox account).
   - **Version release**: choose **Manually release this version**, so you control launch day.
2. **App Privacy** (sidebar): answers are in section 3 of the metadata file. Purchase History (App Functionality, Analytics) and User ID (App Functionality), both not linked to identity, no tracking.
3. **Age rating**: every answer is None or No (table in section 1 of the metadata file), which gives 4+.
4. **Pricing and Availability**: price **Free** (the subscriptions are inside the app), all countries.
5. Go through the **release checklist** below, then press **Add for Review** > **Submit**.

### Release checklist (PLAN.md section 9)
- [ ] Tests pass (⌘U)
- [ ] Release build: RevenueCat logs at `.warn` (already handled by `#if DEBUG`), the key is the production `appl_` key, no test keys
- [ ] Marketing version **1.0.0**, build number **1** (raise the build number on every new upload, e.g. after a rejection fix)
- [ ] Screenshots, metadata and release notes are entered
- [ ] Sandbox purchases checked on the TestFlight build
- [ ] Phased release: turn on **Phased Release for Automatic Updates** for 1.0.1 and later. It doesn't apply to a first release.
- [ ] Content: 1.0.0 ships 99 lessons in 4 tracks (34 free). Read through and fact-check them, because errors in ML lessons hurt reviews and credibility.

## Phase 8: After review

- **Approved**: press **Release This Version**. The app appears on the store within about 24 hours.
- **Rejected**: open Resolution Center, paste the reviewer's message into this thread, and I'll identify the guideline and draft a fix or a reply. Raise the build number, upload, and resubmit.
- Week 1: watch RevenueCat Charts (trial starts, conversion), and set up the founding-member Offer Codes ($59.99 first year) for Product Hunt and Reddit.
