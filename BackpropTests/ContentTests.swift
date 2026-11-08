import XCTest
@testable import Backprop

@MainActor
final class ContentTests: XCTestCase {
    func testBundledContentLoads() {
        let library = ContentLibrary.loadBundled()
        XCTAssertNil(library.loadError)
        XCTAssertFalse(library.tracks.isEmpty)
        for id in library.allLessonIDs {
            XCTAssertNotNil(library.lesson(id: id), "missing \(id)")
        }
    }

    func testAccessPolicy() {
        XCTAssertFalse(ContentAccess.isLocked(chapterIndex: 0, freeChapterCount: 2, isPro: false))
        XCTAssertFalse(ContentAccess.isLocked(chapterIndex: 1, freeChapterCount: 2, isPro: false))
        XCTAssertTrue(ContentAccess.isLocked(chapterIndex: 2, freeChapterCount: 2, isPro: false))
        XCTAssertFalse(ContentAccess.isLocked(chapterIndex: 2, freeChapterCount: 2, isPro: true))
    }

    func testSoftGateIsLastLessonOfLastFreeChapter() {
        let library = ContentLibrary.loadBundled()
        guard let track = library.tracks.first(where: { $0.chapters.count > library.freeChapterCount }) else {
            return XCTFail("need a track with Pro chapters")
        }
        let lastFree = track.chapters[library.freeChapterCount - 1]
        XCTAssertTrue(library.isEndOfFreeContent(lessonID: lastFree.lessonIDs.last!, in: track))
        XCTAssertFalse(library.isEndOfFreeContent(lessonID: track.chapters[0].lessonIDs[0], in: track))
    }

    func testQuizWithBadAnswerIndexIsRejected() {
        let json = #"{"id":"x","title":"x","minutes":1,"steps":[{"type":"quiz","question":"q","choices":["a"],"answerIndex":3,"explanation":"e"}]}"#
        XCTAssertThrowsError(try JSONDecoder().decode(Lesson.self, from: Data(json.utf8)))
    }

    func testUnknownLessonInManifestIsRejected() throws {
        let manifest = ContentManifest(contentVersion: 1, freeChapterCount: 1, tracks: [
            Track(id: "t", title: "t", summary: "", systemImage: "x",
                  chapters: [Chapter(id: "c", title: "c", lessonIDs: ["missing"])]),
        ])
        XCTAssertThrowsError(try ContentLibrary(manifest: manifest, lessons: []))
    }

    func testLessonSessionScoring() throws {
        let library = ContentLibrary.loadBundled()
        let lesson = try XCTUnwrap(library.lesson(id: "df-mean-median"))
        let session = LessonSession(lesson: lesson)
        while let step = session.currentStep {
            if case .quiz(let quiz) = step {
                XCTAssertFalse(session.canAdvance)
                session.select(choice: quiz.answerIndex)
            }
            session.advance()
        }
        XCTAssertTrue(session.isFinished)
        XCTAssertEqual(session.correctCount, lesson.quizSteps.count)
    }

    func testPublicKeyValidation() {
        XCTAssertTrue(AppConfig.isValidPublicAppleKey("appl_abc123"))
        XCTAssertFalse(AppConfig.isValidPublicAppleKey("sk_secret"))
        XCTAssertFalse(AppConfig.isValidPublicAppleKey(nil))
        XCTAssertFalse(AppConfig.isValidPublicAppleKey("appl_"))
    }
}
