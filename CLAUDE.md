# Backprop — Claude Code context

Backprop is an iOS-first (SwiftUI, iOS 18+) app for learning ML & data science in 5-minute interactive lessons, monetized with a RevenueCat-managed subscription.

**Read [PLAN.md](PLAN.md) first.** It is the source of truth for scope, pricing, architecture, compliance, and roadmap. If code and plan disagree, ask before changing either.

## Key decisions (from PLAN.md)
- SwiftUI + `@Observable` + Swift Concurrency; SwiftData for progress/streaks.
- Modules: Content, LessonEngine, Widgets, Progress, Paywall, Analytics.
- Content is bundled JSON/Markdown; any remote updates are content only, never executable code (guideline 2.5.2).
- Purchases via RevenueCat (`purchases-ios` + `RevenueCatUI`, SPM). One subscription group `backprop_pro`, one entitlement `pro`. Gate on `customerInfo.entitlements["pro"]?.isActive == true`.
- Only the public RevenueCat iOS SDK key goes in the app. Secret keys and any LLM API keys live on the backend only.
- Release builds must not use `Purchases.logLevel = .debug`.

## Release rules
- Marketing version follows semver; build number increments on every upload.
- Run the release checklist in PLAN.md section 9 before each submission.
