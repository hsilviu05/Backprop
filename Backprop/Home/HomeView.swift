import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(ContentLibrary.self) private var content
    @Environment(EntitlementStore.self) private var entitlements
    @AppStorage(OnboardingAnswers.levelKey) private var level = ""
    @Query private var completions: [LessonCompletion]
    @Query private var studyDays: [StudyDay]
    @State private var path = NavigationPath()

    private var completedIDs: Set<String> { Set(completions.map(\.lessonID)) }
    private var dayKeys: Set<String> { Set(studyDays.map(\.dayKey)) }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                        .appearAnimation()

                    StatsCard(
                        streak: StreakCalculator.currentStreak(studyDays: dayKeys, now: .now, calendar: .current),
                        studiedToday: StreakCalculator.hasStudied(on: .now, studyDays: dayKeys, calendar: .current),
                        xp: XP.total(for: completions),
                        lessonsDone: completedIDs.count
                    )
                    .appearAnimation(delay: 0.05)

                    if let route = content.nextLesson(
                        completedIDs: completedIDs,
                        isPro: entitlements.isPro,
                        preferredTrackID: OnboardingAnswers.preferredTrackID(level: level)
                    ), let track = content.track(id: route.trackID), let lesson = content.lesson(id: route.lessonID) {
                        ContinueCard(track: track, lesson: lesson) { path.append(route) }
                            .appearAnimation(delay: 0.1)
                    }

                    Text("Tracks")
                        .font(.title2.bold())
                        .padding(.top, 4)
                        .appearAnimation(delay: 0.15)

                    VStack(spacing: Theme.spacing) {
                        ForEach(Array(content.tracks.enumerated()), id: \.element.id) { index, track in
                            NavigationLink(value: track) {
                                TrackCard(track: track, completedIDs: completedIDs)
                            }
                            .buttonStyle(.plain)
                            .appearAnimation(delay: 0.18 + Double(index) * 0.05)
                        }
                    }
                }
                .padding(.horizontal, Theme.padding)
                .padding(.bottom, 32)
            }
            .screenBackground()
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Track.self) { TrackView(track: $0) }
            .navigationDestination(for: LessonRoute.self) { route in
                if let track = content.track(id: route.trackID), let lesson = content.lesson(id: route.lessonID) {
                    LessonView(lesson: lesson, track: track)
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            BackpropMark(size: 34, animated: true)
            Text("Backprop")
                .font(.largeTitle.bold())
            Spacer()
            if entitlements.isPro {
                Text("PRO")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .foregroundStyle(Color.accentColor)
                    .background(Color.accentColor.opacity(0.15), in: Capsule())
            }
        }
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

private struct StatsCard: View {
    let streak: Int
    let studiedToday: Bool
    let xp: Int
    let lessonsDone: Int

    var body: some View {
        HStack(spacing: 0) {
            stat(value: streak, label: "day streak", systemImage: "flame.fill", tint: .accentColor)
                .symbolEffect(.bounce, value: studiedToday)
            Divider().frame(height: 36)
            stat(value: xp, label: "XP", systemImage: "star.fill", tint: .accentColor)
            Divider().frame(height: 36)
            stat(value: lessonsDone, label: "lessons", systemImage: "checkmark.circle.fill", tint: .accentColor)
        }
        .padding(.vertical, 16)
        .cardSurface()
    }

    private func stat(value: Int, label: String, systemImage: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: systemImage).foregroundStyle(tint)
                Text("\(value)")
                    .font(.title2.bold().monospacedDigit())
                    .contentTransition(.numericText(value: Double(value)))
            }
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

private struct ContinueCard: View {
    let track: Track
    let lesson: Lesson
    let onStart: () -> Void

    var body: some View {
        let tint = Theme.trackTint(track.id)
        Button(action: onStart) {
            HStack(spacing: 14) {
                IconTile(systemImage: track.systemImage, tint: tint, size: 52)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Up next · \(track.title)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(lesson.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    Label("\(lesson.minutes) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(tint)
                    .symbolRenderingMode(.hierarchical)
            }
            .padding(Theme.padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .cardSurface(tint: tint, interactive: true)
        .accessibilityHint("Starts the lesson")
    }
}

private struct TrackCard: View {
    let track: Track
    let completedIDs: Set<String>

    var body: some View {
        let ids = track.chapters.flatMap(\.lessonIDs)
        let done = ids.filter(completedIDs.contains).count
        let tint = Theme.trackTint(track.id)
        HStack(spacing: 14) {
            IconTile(systemImage: track.systemImage, tint: tint)
            VStack(alignment: .leading, spacing: 3) {
                Text(track.title).font(.headline).foregroundStyle(.primary)
                Text(track.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text("\(done) of \(ids.count) lessons")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 8)
            ProgressRing(progress: ids.isEmpty ? 0 : Double(done) / Double(ids.count), tint: tint, size: 36)
        }
        .padding(Theme.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .cardSurface(interactive: true)
    }
}
