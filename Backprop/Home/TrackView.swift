import SwiftData
import SwiftUI

struct TrackView: View {
    let track: Track
    @Environment(ContentLibrary.self) private var content
    @Environment(EntitlementStore.self) private var entitlements
    @Query private var completions: [LessonCompletion]
    @State private var showPaywall = false

    var body: some View {
        let completedIDs = Set(completions.map(\.lessonID))
        let tint = Theme.trackTint(track.id)
        let ids = track.chapters.flatMap(\.lessonIDs)
        let done = ids.filter(completedIDs.contains).count

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 14) {
                    IconTile(systemImage: track.systemImage, tint: tint, size: 56)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(track.summary).font(.subheadline).foregroundStyle(.secondary)
                        Text("\(done) of \(ids.count) lessons complete").font(.caption).foregroundStyle(.tertiary)
                    }
                    Spacer()
                    ProgressRing(progress: ids.isEmpty ? 0 : Double(done) / Double(ids.count), tint: tint, size: 44)
                }
                .appearAnimation()

                ForEach(Array(track.chapters.enumerated()), id: \.element.id) { index, chapter in
                    ChapterCard(
                        number: index + 1,
                        chapter: chapter,
                        track: track,
                        tint: tint,
                        isLocked: content.isLocked(chapterIndex: index, isPro: entitlements.isPro),
                        completedIDs: completedIDs,
                        onUnlock: { showPaywall = true }
                    )
                    .appearAnimation(delay: 0.04 * Double(min(index, 6)))
                }
            }
            .padding(.horizontal, Theme.padding)
            .padding(.bottom, 32)
        }
        .screenBackground(tint: tint)
        .navigationTitle(track.title)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showPaywall) { PaywallSheet() }
    }
}

private struct ChapterCard: View {
    let number: Int
    let chapter: Chapter
    let track: Track
    let tint: Color
    let isLocked: Bool
    let completedIDs: Set<String>
    let onUnlock: () -> Void

    @Environment(ContentLibrary.self) private var content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Chapter \(number)").font(.caption.weight(.semibold)).foregroundStyle(tint)
                    Text(chapter.title).font(.headline)
                }
                Spacer()
                if isLocked {
                    Label("Pro", systemImage: "lock.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, Theme.padding)
            .padding(.top, Theme.padding)
            .padding(.bottom, 8)

            ForEach(chapter.lessonIDs, id: \.self) { id in
                if let lesson = content.lesson(id: id) {
                    Divider().padding(.leading, Theme.padding + 34)
                    if isLocked {
                        Button(action: onUnlock) {
                            LessonRow(lesson: lesson, state: .locked, tint: tint)
                        }
                        .buttonStyle(.plain)
                    } else {
                        NavigationLink(value: LessonRoute(trackID: track.id, lessonID: id)) {
                            LessonRow(lesson: lesson, state: completedIDs.contains(id) ? .done : .open, tint: tint)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if isLocked {
                Button(action: onUnlock) {
                    Text("Unlock with Pro").frame(maxWidth: .infinity)
                }
                .secondaryButtonStyle()
                .padding(Theme.padding)
            } else {
                Spacer().frame(height: 6)
            }
        }
        .cardSurface()
    }
}

private struct LessonRow: View {
    enum RowState { case open, done, locked }

    let lesson: Lesson
    let state: RowState
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            Group {
                switch state {
                case .done: Image(systemName: "checkmark.circle.fill").foregroundStyle(tint)
                case .open: Image(systemName: "circle").foregroundStyle(tint)
                case .locked: Image(systemName: "lock.fill").foregroundStyle(.secondary)
                }
            }
            .font(.body)
            .frame(width: 22)
            Text(lesson.title)
                .foregroundStyle(state == .locked ? .secondary : .primary)
                .multilineTextAlignment(.leading)
            Spacer()
            Text("\(lesson.minutes) min").font(.caption).foregroundStyle(.secondary)
            if state != .locked {
                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, Theme.padding)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityValue(state == .done ? "Completed" : state == .locked ? "Locked, requires Pro" : "")
    }
}
