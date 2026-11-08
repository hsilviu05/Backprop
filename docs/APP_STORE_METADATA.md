# App Store Connect copy-paste sheet: Backprop 1.0.0

Every field you need for the first submission, in the order the App Store Connect screens show them. Each heading names the **screen › field**. Copy the code block underneath it as is.

Character limits are Apple's maximums and are checked by `docs/check_metadata.py` (run `python3 docs/check_metadata.py`).

Values that are fixed elsewhere and must match exactly:

| Thing | Value |
|---|---|
| Bundle ID | `com.silviu.backprop` |
| SKU | `backprop-ios` |
| Version | `1.0.0` (build `1`) |
| Subscription group (reference name) | `backprop_pro` |
| Yearly product ID | `backprop_pro_yearly`: $79.99/year, 7-day free trial |
| Monthly product ID | `backprop_pro_monthly`: $12.99/month, first month $4.99 |
| RevenueCat entitlement | `pro` |

---

## 1. App Information (left sidebar › App Information)

### App Information › Name (max 30)
```
Backprop: Learn ML & AI
```

### App Information › Subtitle (max 30)
```
Data science in 5-min lessons
```

### App Information › Category › Primary
```
Education
```

### App Information › Category › Secondary
```
Reference
```

### App Information › Content Rights
Answer: **Yes, it contains, shows, or accesses third-party content**, then tick **I have the necessary rights**.

Why: the Reading tab shows book covers from Open Library and YouTube video thumbnails, and links to third-party books, papers and courses. Lesson text, quizzes and sims are original.

### App Information › Age Rating (Set Up Age Ratings)
Answer **None** or **No** to every question. Expected result: **4+**.

| Section | Question | Answer |
|---|---|---|
| In-App Controls | Parental Controls | No |
| In-App Controls | Age Assurance | No |
| Capabilities | Unrestricted Web Access | No (see note) |
| Capabilities | User-Generated Content | No |
| Capabilities | Messaging and Chat | No |
| Capabilities | Advertising | No |
| Capabilities | Social media (redistribute or interact with user content in a feed) | No |
| Mature Themes | Profanity or Crude Humor | None |
| Mature Themes | Horror/Fear Themes | None |
| Mature Themes | Alcohol, Tobacco, or Drug Use or References | None |
| Medical or Wellness | Medical or Treatment Information | None |
| Medical or Wellness | Health or Wellness Topics | No |
| Sexuality or Nudity | All questions | None |
| Violence | All questions | None |
| Chance-Based Activities | Simulated Gambling, Contests | None |
| Chance-Based Activities | Gambling, Loot Boxes | No |

Note on Unrestricted Web Access: the Reading tab opens a fixed, bundled list of links in Safari View Controller, which has no address bar, and videos open in the YouTube app. That's curated links, not a browser, so the answer is No. Answering Yes would force 16+.

### App Information › Copyright
Goes on the version page (section 2), listed here so all fixed text is in one place:
```
2026 Silviu Hermeneanu
```

---

## 2. Version page (App Store tab › iOS App › 1.0 Prepare for Submission)

### Version › Promotional Text (max 170)
Can be changed any time without a new build.
```
Finally understand machine learning. Drag data points, tune learning rates and watch models learn in 5-minute lessons. Start free, no account needed.
```

### Version › Description (max 4000)
```
Backprop teaches machine learning the way it actually clicks: by playing with it.

Every lesson takes about five minutes. Read a short idea, try it in a live simulation, then check yourself with a few quick questions. Build a daily streak and watch your XP grow.

LEARN BY DOING
• Drag points around and watch a regression line refit in real time
• Roll a ball down a loss curve and see what a learning rate really does, including when training blows up
• Every concept ends with a quick quiz and clear explanations

99 LESSONS IN 4 TRACKS
• Data foundations: describing data, probability, distributions, inference, working with data
• Classic ML: regression, optimization, classification, trees and ensembles, unsupervised learning, evaluation
• Neural networks: neurons, backpropagation, training tricks, generalization, CNNs, sequence models
• Modern AI: tokens and embeddings, attention, transformers, large language models, retrieval-augmented generation

A READING LIST WORTH YOUR TIME
The Reading tab collects the best books, videos, papers, articles and courses on ML and AI, sorted from beginner to advanced, so you always know what to read next.

BUILT FOR BUSY PEOPLE
• 5-minute lessons that fit a coffee break
• Daily streaks and XP to keep you going
• Lessons work offline
• No account, no ads, no tracking

START FREE
The first two chapters of every track are free: 34 lessons in total. Backprop Pro unlocks all 99 lessons and every future track.

SUBSCRIPTION DETAILS
Backprop Pro is available as a yearly subscription with a 7-day free trial, or as a monthly subscription with a discounted first month. Payment is charged to your Apple Account when you confirm the purchase, or when the free trial ends. Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period, and your account is charged for renewal within 24 hours before the period ends. Manage or cancel anytime in your Apple Account settings.

Terms of Use: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Privacy Policy: https://hsilviu05.github.io/Backprop/legal/privacy.html
```

### Version › Keywords (max 100, commas, no spaces after commas)
Words already in the name and subtitle (Backprop, learn, ML, AI, data, science, lessons) are indexed already, so they're left out here.
```
machine learning,statistics,neural network,deep learning,LLM,transformer,regression,probability,quiz
```

### Version › Support URL
```
https://hsilviu05.github.io/Backprop/support.html
```

### Version › Marketing URL (optional)
Leave empty for 1.0. Add a landing page later if you make one.

### Version › Version
```
1.0.0
```

### Version › Copyright
```
2026 Silviu Hermeneanu
```

### Version › What's New in This Version (max 4000)
App Store Connect doesn't show this field for an app's first version. Keep this for 1.0.1, or paste it if the field appears.
```
Welcome to Backprop! 99 interactive 5-minute lessons across stats, classic ML, neural networks and modern AI, live simulations, quizzes, daily streaks and a curated reading list.
```

### Version › In-App Purchases and Subscriptions
Click **Select In-App Purchases or Subscriptions** and add both `backprop_pro_yearly` and `backprop_pro_monthly`. This is required for the first version: they're reviewed together with the app.

### Version › App Review Information › Sign-In Required
Untick **Sign-in required**. The app has no accounts.

### Version › App Review Information › Contact Information
Your own first name, last name, phone number and email. Apple calls this number if something blocks the review.

### Version › App Review Information › Notes (max 4000)
```
Backprop is an app for learning machine learning and data science in short interactive lessons. No account or sign-in is needed.

TESTING THE SUBSCRIPTION
Please use a Sandbox Apple Account (sandbox tester) to test purchases. No real charges are made.
1. Complete the short onboarding (goal, level, daily time). The paywall appears at the end and can be closed with the X button, so all free content stays available without purchasing.
2. Free content: chapters 1 and 2 of each of the 4 tracks (34 of 99 lessons). Chapter 3 onward shows a lock and opens the paywall when tapped. The paywall also appears after the last free lesson of a track.
3. Products in the group "Backprop Pro": backprop_pro_yearly ($79.99/year with a 7-day free trial) and backprop_pro_monthly ($12.99/month, first month $4.99). Purchases use StoreKit through the RevenueCat SDK.
4. Settings tab: "Restore purchases" and "Manage subscription". Terms of Use and Privacy Policy links are in Settings and on the paywall.

OTHER NOTES
- All lessons, quizzes and simulations are bundled in the app. The app doesn't download executable code and has no AI chat or AI-generated content.
- The Reading tab is a fixed, bundled list of links to books, papers, articles, courses and videos. Links open in Safari View Controller, and videos open in YouTube.
- No ads, no tracking, no third-party analytics.
```

### Version › Version Release
Choose **Manually release this version**.

---

## 3. App Privacy (left sidebar › App Privacy)

### App Privacy › Privacy Policy URL
```
https://hsilviu05.github.io/Backprop/legal/privacy.html
```

### App Privacy › Data Collection
"Do you or your third-party partners collect data from this app?" **Yes, we collect data from this app.**

Tick only these two data types, then click **Save** and fill in each one:

| Data type | Purposes (tick) | Linked to the user's identity? | Used for tracking? |
|---|---|---|---|
| **Purchases › Purchase History** | App Functionality, Analytics | No | No |
| **Identifiers › User ID** | App Functionality | No | No |

Leave every other type unticked: Contact Info, Health & Fitness, Financial Info, Location, Sensitive Info, Contacts, User Content, Browsing History, Search History, Usage Data, Diagnostics, Device ID and Other Data.

Why these answers:
- RevenueCat's own guide says Purchase History is required, with both App Functionality (receipt validation, entitlements) and Analytics (its dashboard charts).
- The app never calls `Purchases.logIn`, so RevenueCat uses a random anonymous ID. That ID can't be tied to a name, email or Apple Account, so "linked to identity" is No. Declaring it as User ID is the cautious choice and matches the privacy policy.
- No IDFA, ad networks or analytics SDKs, so there's no tracking and no Device ID or Usage Data.
- Progress, streaks and onboarding answers stay on the device, which doesn't count as collection.

---

## 4. Subscriptions (left sidebar › Monetization › Subscriptions)

### Subscription Group › Reference Name
```
backprop_pro
```

### Subscription Group › Localization (English (U.S.)) › Subscription Group Display Name
```
Backprop Pro
```

### Subscription Group › Localization › App Name Display Options
Choose **Use App Name**.

### Yearly › Reference Name
```
Pro Yearly
```

### Yearly › Product ID
```
backprop_pro_yearly
```

### Yearly › Localization › Display Name (max 35)
```
Backprop Pro (Yearly)
```

### Yearly › Localization › Description (max 55)
```
Every lesson, track and sim, billed once a year.
```

### Monthly › Reference Name
```
Pro Monthly
```

### Monthly › Product ID
```
backprop_pro_monthly
```

### Monthly › Localization › Display Name (max 35)
```
Backprop Pro (Monthly)
```

### Monthly › Localization › Description (max 55)
```
Every lesson, track and sim, billed every month.
```

Settings for both products (not text fields):
- **Duration**: yearly 1 year, monthly 1 month.
- **Price**: yearly $79.99, monthly $12.99 (US base, let Apple set the other countries).
- **Levels**: yearly on level 1, monthly on level 2.
- **Introductory offer**: yearly Free, 1 week, all countries. Monthly Pay as you go, $4.99, 1 month, all countries.
- **Review Information › Screenshot**: a screenshot of the paywall from the TestFlight build.
- **Review Information › Review Notes** (optional), for both products:
```
Unlocks every chapter of every track in Backprop. Purchase from the paywall shown after onboarding or by tapping a locked chapter. Please use a Sandbox Apple Account to test.
```

---

## 5. Pricing and Availability (left sidebar › Pricing and Availability)

- **Price**: Free (USD 0.00). Pro is sold through the subscriptions.
- **Availability**: all countries and regions.

## 6. Other one-time answers

- **Export compliance**: Info.plist already sets `ITSAppUsesNonExemptEncryption = NO`, so App Store Connect won't ask. The app only uses Apple's built-in HTTPS.
- **EU Digital Services Act trader status** (Business › Compliance): required before the app can be sold in the EU. If you declare yourself a trader, your address, phone and email become public on the EU store page.
- **App Store Server Notifications**: see LAUNCH.md Phase 3.3 (RevenueCat URL, version 2, Production and Sandbox).

---

## Release notes for the repo (CHANGELOG)
### 1.0.0
- 99 interactive lessons in 4 tracks: Data foundations, Classic ML, Neural networks, Modern AI (34 free)
- Live simulations: linear regression and gradient descent
- Quizzes with explanations, daily streaks, XP
- Reading tab: curated ML and AI books, videos, papers, articles and courses
- One-accent-color redesign
- Backprop Pro subscription (yearly with 7-day trial, monthly with discounted first month) via RevenueCat, with Customer Center and Restore
