import Foundation
import Observation

/// Loads and validates the bundled lesson content.
@MainActor
@Observable
final class ContentLibrary {
    private(set) var tracks: [Track] = []
    private(set) var freeChapterCount = 0
    private(set) var loadError: String?
    private var lessons: [String: Lesson] = [:]

    init(manifest: ContentManifest, lessons: [Lesson]) throws {
        let byID = Dictionary(lessons.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        guard byID.count == lessons.count else {
            throw ContentError.duplicateLessonID
        }
        for track in manifest.tracks {
            for chapter in track.chapters {
                guard !chapter.lessonIDs.isEmpty else { throw ContentError.emptyChapter(chapter.id) }
                for id in chapter.lessonIDs where byID[id] == nil {
                    throw ContentError.missingLesson(id)
                }
            }
        }
        self.tracks = manifest.tracks
        self.freeChapterCount = max(0, manifest.freeChapterCount)
        self.lessons = byID
    }

    private init(loadError: String) {
        self.loadError = loadError
    }

    static func loadBundled(bundle: Bundle = .main) -> ContentLibrary {
        do {
            let decoder = JSONDecoder()
            guard let manifestURL = bundle.url(forResource: "manifest", withExtension: "json") else {
                throw ContentError.missingManifest
            }
            let manifest = try decoder.decode(ContentManifest.self, from: Data(contentsOf: manifestURL))
            // Lesson files are copied flat into the bundle as lesson-*.json.
            let lessonURLs = (bundle.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? [])
                .filter { $0.lastPathComponent.hasPrefix("lesson-") }
            let lessons = try lessonURLs.map { url in
                do {
                    return try decoder.decode(Lesson.self, from: Data(contentsOf: url))
                } catch {
                    throw ContentError.invalidLesson(url.lastPathComponent, String(describing: error))
                }
            }
            return try ContentLibrary(manifest: manifest, lessons: lessons)
        } catch {
            return ContentLibrary(loadError: String(describing: error))
        }
    }

    func lesson(id: String) -> Lesson? { lessons[id] }

    func track(id: String) -> Track? { tracks.first { $0.id == id } }

    /// The first unfinished lesson the user can open, checking the preferred track first.
    func nextLesson(completedIDs: Set<String>, isPro: Bool, preferredTrackID: String?) -> LessonRoute? {
        let ordered = tracks.filter { $0.id == preferredTrackID } + tracks.filter { $0.id != preferredTrackID }
        for track in ordered {
            for (index, chapter) in track.chapters.enumerated() where !isLocked(chapterIndex: index, isPro: isPro) {
                if let id = chapter.lessonIDs.first(where: { !completedIDs.contains($0) }) {
                    return LessonRoute(trackID: track.id, lessonID: id)
                }
            }
        }
        return nil
    }

    var allLessonIDs: [String] {
        tracks.flatMap { $0.chapters.flatMap(\.lessonIDs) }
    }

    func isLocked(chapterIndex: Int, isPro: Bool) -> Bool {
        ContentAccess.isLocked(chapterIndex: chapterIndex, freeChapterCount: freeChapterCount, isPro: isPro)
    }

    /// True when this lesson is the final lesson of the last free chapter: the soft paywall gate.
    func isEndOfFreeContent(lessonID: String, in track: Track) -> Bool {
        let lastFreeIndex = freeChapterCount - 1
        guard track.chapters.indices.contains(lastFreeIndex),
              track.chapters.count > freeChapterCount else { return false }
        return track.chapters[lastFreeIndex].lessonIDs.last == lessonID
    }
}

struct LessonRoute: Hashable, Sendable {
    let trackID: String
    let lessonID: String
}

enum ContentAccess {
    static func isLocked(chapterIndex: Int, freeChapterCount: Int, isPro: Bool) -> Bool {
        !isPro && chapterIndex >= freeChapterCount
    }
}

enum ContentError: Error, CustomStringConvertible {
    case missingManifest
    case duplicateLessonID
    case emptyChapter(String)
    case missingLesson(String)
    case invalidLesson(String, String)

    var description: String {
        switch self {
        case .missingManifest: "manifest.json is missing from the app bundle."
        case .duplicateLessonID: "Two lesson files share the same id."
        case .emptyChapter(let id): "Chapter \(id) has no lessons."
        case .missingLesson(let id): "Lesson \(id) is listed in the manifest but has no file."
        case .invalidLesson(let file, let detail): "\(file) is invalid: \(detail)"
        }
    }
}
