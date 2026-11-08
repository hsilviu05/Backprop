# Backprop

Learn ML & data science in 5-minute interactive lessons. iOS 18+, SwiftUI, RevenueCat.

- Plan: [PLAN.md](PLAN.md) · Launch guide (App Store Connect, RevenueCat, build, test, submit): [docs/LAUNCH.md](docs/LAUNCH.md) · Store copy: [docs/APP_STORE_METADATA.md](docs/APP_STORE_METADATA.md)

## Build
```sh
brew install xcodegen
cp Config/Secrets.example.xcconfig Config/Secrets.xcconfig   # fill in your values
xcodegen generate && open Backprop.xcodeproj
```

## Layout
| Folder | What |
|---|---|
| `Backprop/App` | App entry, config, RevenueCat bootstrap |
| `Backprop/Content` | Content models, manifest loading and validation, free/Pro access policy |
| `Backprop/LessonEngine` | Lesson session state, lesson/quiz UI, ML math |
| `Backprop/Widgets` | Interactive sims (regression, gradient descent) |
| `Backprop/Progress` | SwiftData progress, streaks, XP |
| `Backprop/Paywall` | Entitlement store, RevenueCat paywall and Customer Center |
| `Backprop/Resources/Content` | `manifest.json` + `lessons/lesson-*.json` |

## Adding a lesson
1. Add `Backprop/Resources/Content/lessons/lesson-<id>.json` (steps: `text`, `widget`, `quiz`).
2. List `<id>` in a chapter in `manifest.json`. Chapters at index ≥ `freeChapterCount` are Pro.
3. Run the tests: `ContentTests` fails if a listed lesson is missing or a quiz answer index is out of range.
