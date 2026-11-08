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
| `Backprop/Reading` | Free recommended-reading tab: book covers, YouTube videos, articles, papers and courses |
| `Backprop/Resources/Content` | `manifest.json` + `lessons/lesson-*.json` + `reading.json` |

## Adding a lesson
1. Add `Backprop/Resources/Content/lessons/lesson-<id>.json` (steps: `text`, `widget`, `quiz`).
2. List `<id>` in a chapter in `manifest.json`. Chapters at index ≥ `freeChapterCount` are Pro.
3. Run the tests: `ContentTests` fails if a listed lesson is missing, a quiz answer index is out of range, or a lesson doesn't have 3–5 quiz questions.

## Adding a reading item
Add an entry to `Backprop/Resources/Content/reading.json` (`kind`: `book`, `video`, `article`, `paper` or `course`; `level`: `beginner`, `intermediate` or `advanced`; `year` is optional). Books can add a print `isbn` (ISBN-13) to show the Open Library cover; videos need `youtubeID` and a `https://www.youtube.com/watch?v=<id>` link. Links must be https and free to read: no affiliate or store links (guideline 3.1.1). `ReadingTests` checks ids, links and required fields.
