import XCTest
@testable import Backprop

final class ReadingTests: XCTestCase {
    func testBundledReadingListLoads() throws {
        let items = try ReadingLibrary.loadBundled().get()
        XCTAssertGreaterThanOrEqual(items.count, 20)
        for kind in ReadingItem.Kind.allCases {
            XCTAssertTrue(items.contains { $0.kind == kind }, "no \(kind) items")
        }
        for video in items where video.kind == .video {
            XCTAssertNotNil(video.thumbnailURL, video.id)
        }
        XCTAssertTrue(items.contains { $0.coverURL != nil }, "no book covers")
    }

    func testHTTPLinkIsRejected() {
        XCTAssertThrowsError(try decode(Self.item(url: "http://example.com"))) { error in
            guard case ReadingError.insecureURL = error else { return XCTFail("got \(error)") }
        }
    }

    func testDuplicateIDIsRejected() {
        let item = Self.item()
        let json = #"{"listVersion":1,"items":[\#(item),\#(item)]}"#
        XCTAssertThrowsError(try ReadingLibrary.decode(Data(json.utf8))) { error in
            guard case ReadingError.duplicateID = error else { return XCTFail("got \(error)") }
        }
    }

    func testUnknownKindIsRejected() {
        XCTAssertThrowsError(try decode(Self.item(kind: "podcast")))
    }

    func testValidVideoIsAccepted() throws {
        let items = try decode(Self.item(kind: "video", url: "https://www.youtube.com/watch?v=aircAruvnKk",
                                         extra: #","youtubeID":"aircAruvnKk""#))
        XCTAssertEqual(items.first?.thumbnailURL?.absoluteString, "https://i.ytimg.com/vi/aircAruvnKk/mqdefault.jpg")
    }

    func testVideoNeedsMatchingYouTubeLink() {
        let cases = [
            Self.item(kind: "video", url: "https://www.youtube.com/watch?v=aircAruvnKk"),
            Self.item(kind: "video", url: "https://www.youtube.com/watch?v=IHZwWFHWa-w", extra: #","youtubeID":"aircAruvnKk""#),
            Self.item(kind: "video", url: "https://example.com/watch?v=aircAruvnKk", extra: #","youtubeID":"aircAruvnKk""#),
            Self.item(kind: "video", url: "https://www.youtube.com/watch?v=short", extra: #","youtubeID":"short""#),
            Self.item(kind: "book", extra: #","youtubeID":"aircAruvnKk""#),
        ]
        for json in cases {
            XCTAssertThrowsError(try decode(json)) { error in
                guard case ReadingError.invalidVideo = error else { return XCTFail("got \(error)") }
            }
        }
    }

    func testISBNChecksum() {
        XCTAssertTrue(ReadingLibrary.isValidISBN13("9780262035613"))
        XCTAssertFalse(ReadingLibrary.isValidISBN13("9780262035614"))
        XCTAssertFalse(ReadingLibrary.isValidISBN13("978-0262035613"))
        XCTAssertThrowsError(try decode(Self.item(extra: #","isbn":"9780262035614""#)))
    }

    func testLevelsSortBeginnerFirst() {
        XCTAssertEqual([ReadingItem.Level.advanced, .beginner, .intermediate].sorted(), [.beginner, .intermediate, .advanced])
    }

    private func decode(_ item: String) throws -> [ReadingItem] {
        try ReadingLibrary.decode(Data(#"{"listVersion":1,"items":[\#(item)]}"#.utf8))
    }

    private static func item(kind: String = "book", url: String = "https://example.com", extra: String = "") -> String {
        #"{"id":"x","kind":"\#(kind)","title":"T","authors":"A","year":2020,"url":"\#(url)","summary":"S","level":"beginner","topic":"Basics"\#(extra)}"#
    }
}
