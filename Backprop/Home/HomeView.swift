import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(ContentLibrary.self) private var content
    @Environment(EntitlementStore.self) private var entitlements
    @Query private var completions: [LessonCompletion]
    @Query private var studyDays: [StudyDay]

    private var completedIDs: Set<String> { Set(completions.map(\.lessonID)) }

    private var streak: Int {
        StreakCalculator.currentStreak(studyDays: Set(studyDays.map(\.dayKey)), now: .now, calendar: .current)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 24) {
                        StatView(value: "\(streak)", label: "Day streak", systemImage: "flame.fill")
                        StatView(value: "\(XP.total(for: completions))", label: "XP", systemImage: "star.fill")
                        StatView(value: "\(completedIDs.count)", label: "Lessons", systemImage: "checkmark.circle.fill")
                    }
                    .frame(maxWidth: .infinity)
                }
                ForEach(content.tracks) { track in
                    Section(track.title) {
                        NavigationLink(value: track) {
                            TrackRow(track: track, completedIDs: completedIDs)
                        }
                    }
                }
            }
            .navigationTitle("Backprop")
            .navigationDestination(for: Track.self) { TrackView(track: $0) }
        }
    }
}

private struct StatView: View {
    let value: String
    let label: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: systemImage).foregroundStyle(.orange)
            Text(value).font(.title2.bold().monospacedDigit())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct TrackRow: View {
    let track: Track
    let completedIDs: Set<String>

    var body: some View {
        let ids = track.chapters.flatMap(\.lessonIDs)
        let done = ids.filter(completedIDs.contains).count
        HStack(spacing: 16) {
            Image(systemName: track.systemImage).font(.title).foregroundStyle(.tint).frame(width: 40)
            VStack(alignment: .leading, spacing: 4) {
                Text(track.summary).font(.subheadline)
                ProgressView(value: Double(done), total: Double(max(ids.count, 1)))
                Text("\(done) of \(ids.count) lessons").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct TrackView: View {
    let track: Track
    @Environment(ContentLibrary.self) private var content
    @Environment(EntitlementStore.self) private var entitlements
    @Query private var completions: [LessonCompletion]
    @State private var showPaywall = false

    var body: some View {
        let completedIDs = Set(completions.map(\.lessonID))
        List {
            ForEach(Array(track.chapters.enumerated()), id: \.element.id) { index, chapter in
                let locked = content.isLocked(chapterIndex: index, isPro: entitlements.isPro)
                Section {
                    ForEach(chapter.lessonIDs, id: \.self) { id in
                        if let lesson = content.lesson(id: id) {
                            if locked {
                                Button { showPaywall = true } label: {
                                    LessonRow(lesson: lesson, isDone: false, isLocked: true)
                                }
                            } else {
                                NavigationLink {
                                    LessonView(lesson: lesson, track: track)
                                } label: {
                                    LessonRow(lesson: lesson, isDone: completedIDs.contains(id), isLocked: false)
                                }
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("Chapter \(index + 1): \(chapter.title)")
                        if locked { Spacer(); Label("Pro", systemImage: "lock.fill").labelStyle(.titleAndIcon) }
                    }
                }
            }
        }
        .navigationTitle(track.title)
        .sheet(isPresented: $showPaywall) { PaywallSheet() }
    }
}

private struct LessonRow: View {
    let lesson: Lesson
    let isDone: Bool
    let isLocked: Bool

    var body: some View {
        HStack {
            Image(systemName: isLocked ? "lock.fill" : isDone ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isDone ? .green : .secondary)
            Text(lesson.title).foregroundStyle(.primary)
            Spacer()
            Text("\(lesson.minutes) min").font(.caption).foregroundStyle(.secondary)
        }
    }
}
