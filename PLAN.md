# Backprop — Learn ML & Data Science

Project plan · v0.1.1 · Nov 2026 (facts re-checked Nov 8, 2026)

## 0. Assumptions (change these first if wrong)

- iOS-first, SwiftUI, iOS 18+ minimum (iOS 18 is needed for StoreKit win-back offers). Android later via RevenueCat's same entitlements.
- Solo dev, enrolled in Apple Small Business Program (15% commission).
- English only at launch; USD prices below are the US tier — let Apple auto-equalize other storefronts, then tune in RevenueCat Experiments.

## 1. Name

**Backprop** — App Store name: *Backprop: Learn ML & AI* (subtitle: *Data science in 5-min lessons*).

- Short, memorable ML pun, signals "for people who want to actually understand it."
- No exact App Store match found in a quick search — not a trademark check. Before committing: search App Store Connect name availability, USPTO/EUIPO, and the domain/handles.
- Backups: Gradient Daily, Overfit, Tensorly.

## 2. Market scan (Nov 2026)

| App | Focus | Monthly | Yearly | Notes |
|---|---|---|---|---|
| DataCamp | Data science/AI, browser-first | ~$35 | ~$336 (promos ~$168) | Raised prices Aug 2026; deep catalog, weak mobile UX |
| Brilliant | Interactive math/CS/AI | ~$25–30 | ~$149–240 | Best-in-class interactivity; AI is one track among many |
| Mimo | Coding, mobile-first | $9.99 | $79.99 | Pro + Max tiers; trial only on yearly; ~$199 lifetime |
| Sololearn | Coding + AI courses | $6.99–12.99 | $47.99–79.99 | Upsells AI content to a separate MAX tier (users complain) |
| Long tail ("Learn ML", "30 Days of ML", "TechBrain") | ML | $1–7 paid or free | — | Text-dump content, few ratings, dated UI |

**Gap:** nobody owns mobile-first, interactive, ML-specific learning. DataCamp/Brilliant are premium but general or desktop-centric; the ML-specific apps are low quality. Position Backprop as "Brilliant-quality interactivity, ML-only, Mimo-level price."

Benchmarks worth designing around (RevenueCat SOSA 2026):

- Hard paywall + trial ≈ 10.7% download→paid by day 35 vs 2.1% for freemium.
- Longer trials convert better: trial→paid median 42.5% for 17–32-day trials vs 25.5% for ≤4-day trials (5–9 days: 37.4%).
- Education has the highest yearly median price ($44.99) → annual-heavy model fits. (An earlier draft cited ~30% first-month annual cancellation for Education; that figure is not in SOSA 2026, so don't rely on it until sourced.)
- Education annual median ≈ $44.99; $9.99/mo is the most common monthly price.

## 3. Pricing & offers

One subscription group `backprop_pro`, one entitlement `pro`.

| Product ID | Price | Effective | Intro offer |
|---|---|---|---|
| `backprop_pro_yearly` | $79.99/yr | $6.67/mo — save 49% vs monthly ($155.88) | 7-day free trial |
| `backprop_pro_monthly` | $12.99/mo | — | First month $4.99 (pay-as-you-go) |

**Why:** matches Mimo's yearly anchor, undercuts Brilliant/DataCamp by 2–4×, monthly priced high on purpose so yearly is the obvious pick (default-selected on paywall).

**Offer stack (lifecycle):**

1. **Launch — "Founding member":** yearly at $59.99 first year (25% off) via Offer Codes for Product Hunt/Reddit/YouTube for the first 30 days. (Intro offer is one-per-group, so codes are the stackable channel.)
2. **Trial-cancel / paywall-dismiss:** promotional offer, yearly $39.99 first year (50% off) — show once, via RevenueCat Paywall targeting.
3. **Cancel flow:** RevenueCat Customer Center retention offer: monthly at $6.49 for 3 months.
4. **Win-back (iOS 18+):** yearly $49.99 first year, App Store–surfaced, for lapsed 30+ days.
5. **Seasonal:** Black Friday (Nov 27, 2026) / New Year — yearly 50% off via promotional offer. Realistically your first one is New Year 2027.
6. **Later, not at launch:** Lifetime $149.99 (non-consumable). It boosts cash but caps MRR — add only once you have retention data.

Experiments to run in RevenueCat after ~1k paywall views: yearly $79.99 vs $59.99; 7- vs 14-day trial.

## 4. Product (MVP scope)

**Core loop:** daily 5-min lesson → interactive sim → 3–5 question check → streak/XP.

**Tracks** (MVP = first 2 free chapters each, rest Pro):

1. **Data foundations** — stats, probability, distributions, pandas mental model
2. **Classic ML** — regression, classification, trees, k-NN, k-means, evaluation metrics
3. **Neural networks** — perceptron, gradient descent, backprop (signature lesson), CNNs
4. **Modern AI** — embeddings, transformers, attention, LLMs, RAG (v1.1)

**Signature interactive widgets** (SwiftUI + Swift Charts, on-device, no server):

- Drag points → watch linear regression refit live
- Gradient descent ball on a loss surface with learning-rate slider
- k-means stepper; decision boundary playground; confusion matrix builder
- Tiny neural net visualizer with forward/backward pass animation

**Free vs Pro:** Free = first 2 chapters per track + daily streak. Pro = everything, AI tutor, spaced-repetition review, certificates, offline.

**AI tutor (v1.1, Pro):** "Explain this differently" per lesson. Must go through your own backend (Cloudflare Worker / Supabase Edge Function) — never ship an LLM API key in the app. Gate server-side by validating the RevenueCat entitlement (REST API or webhook-synced table), rate-limit per user.

**Deferred (v2):** in-app Python via Pyodide in WKWebView. Guideline 2.5.2 has an exception for educational code apps, but confidence is medium — review the current wording before building.

## 5. Architecture

- SwiftUI, `@Observable`, Swift Concurrency, SwiftData for progress/streaks.
- Content: versioned JSON/Markdown bundled in-app; later remote-updatable via a CDN manifest (content only, no executable code — guideline 2.5.2).
- Modules: Content, LessonEngine, Widgets, Progress, Paywall, Analytics.
- RevenueCat: `purchases-ios` (SPM) + `RevenueCatUI`.
  - `Purchases.configure(withAPIKey:)` with the public iOS SDK key (fine in-app; secret keys only on server).
  - Offering `default` → packages `$rc_annual`, `$rc_monthly`.
  - Gate with `customerInfo.entitlements["pro"]?.isActive == true`; listen to `customerInfoStream`.
  - Paywalls built in RevenueCat dashboard (remote-editable, A/B-testable).
  - Customer Center for manage/cancel/refund-request flows.
  - Upload the In-App Purchase key + App Store Server Notifications V2 URL to RevenueCat (needed for offer codes, win-back tracking).
  - Webhooks → your backend for the AI-tutor entitlement check.
- Identity: anonymous RevenueCat IDs at launch; add Sign in with Apple only when you add sync/AI tutor, then `Purchases.logIn(userID)`.
- Analytics: TelemetryDeck or PostHog (privacy-friendly) for funnel; RevenueCat Charts for MRR, trial conversion, churn, LTV.
- Cost: RevenueCat free until $2.5k MTR, then 1% of tracked revenue (gross, before Apple's cut).

## 6. Paywall placement

1. Onboarding (goal → level → daily time) → personalized plan screen → paywall (trial default on yearly, close button visible).
2. Soft gate at the end of free chapter 2.
3. Settings → "Upgrade."

## 7. App Store compliance checklist

- **3.1.1** All digital unlocks through StoreKit/RevenueCat. Since the guidelines updated Oct 16, 2026 (3.1.1(a), 3.1.3), **US storefront** apps may include buttons/links to external purchase methods without an entitlement; all other storefronts still forbid them. Decision for launch: StoreKit only, no external purchase links anywhere. Revisit for the US storefront later, and re-check the guideline wording first.
- **3.1.2** Paywall shows: price per period, trial length & what it converts to, auto-renew terms, Restore Purchases, links to Terms (EULA) and Privacy Policy. Same links in App Store metadata.
- **4.2 / minimum functionality:** ship with enough real lessons (aim ≥ 40 across 2 tracks) — thin content gets rejected.
- **5.1.1(v):** if you add accounts, in-app account deletion is required.
- **5.1.2:** if the AI tutor sends user content to a third-party AI provider, disclose it and get explicit consent first.
- **Privacy:** `PrivacyInfo.xcprivacy` (include required-reason APIs, e.g. UserDefaults); App Privacy labels must cover RevenueCat (purchase history, identifiers) and your analytics SDK; check each SDK ships its own manifest.
- **Purpose strings:** none needed for MVP (no camera/mic/location). Notifications permission for streak reminders — ask in context, not at launch.
- **Age rating questionnaire** (updated system: 4+, 9+, 13+, 16+, 18+; answers were mandatory from Jan 31, 2026, so every submission needs them). Covers in-app controls, capabilities, medical/wellness and violent themes. Apple asks you to factor in AI assistant/chatbot features, so re-answer it when the AI tutor ships (v1.1).
- **Sandbox + TestFlight test:** purchase, trial, upgrade/downgrade monthly↔yearly, restore, cancel, refund, offer-code redeem, win-back.

## 8. Roadmap & effort (solo, part-time ~15 h/week)

| Phase | Scope | Est. |
|---|---|---|
| 0 | Name/trademark check, App Store Connect app + products, RevenueCat project | 2–3 days |
| 1 | App shell, lesson engine, content format, progress/streaks | 2–3 wks |
| 2 | 4–6 interactive widgets, 40+ lessons (2 tracks) | 3–5 wks (content is the long pole) |
| 3 | RevenueCat SDK, paywall, Customer Center, onboarding | 1 wk |
| 4 | Privacy manifest, metadata, screenshots, TestFlight beta (20–50 users) | 1–2 wks |
| 5 | Launch v1.0 + founding-member codes | — |
| 6 | v1.1: AI tutor + backend, Modern AI track, spaced repetition | 3–4 wks |

Total to v1.0: ~8–12 weeks (medium confidence; content writing dominates).

## 9. Release checklist (each version)

- [ ] Tests pass (unit: lesson engine, entitlement gating; UI: paywall + restore)
- [ ] No debug logging (`Purchases.logLevel` not `.debug` in Release), no test keys
- [ ] Marketing version bumped (semver); build number incremented for every upload
- [ ] Screenshots + metadata + release notes updated
- [ ] TestFlight build validated incl. sandbox purchases
- [ ] Phased release enabled

## 10. Known open questions / risks

- Name availability not verified (trademark + App Store).
- Content creation effort is the main schedule risk — consider writing lessons with Claude, then personally fact-checking every one (ML errors kill credibility).
- Android timing: RevenueCat makes it cheap later; don't build it until iOS retention is proven.
- Price sensitivity outside US/EU — watch RevenueCat per-country conversion and lower tiers where needed.
- Python-in-app guideline interpretation (v2).
