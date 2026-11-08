import XCTest
@testable import Backprop

final class ReadingTests: XCTestCase {
    func testBundledReadingListLoads() throws {
        let items = try ReadingLibrary.loadBundled().get()
        XCTAssertGreaterThanOrEqual(items.count, 20)
        for kind in ReadingItem.Kind.allCases {
            XCTAssertTrue(items.contains { $0.kind == kind }, "no \(kind) items")
        }
    }

    func testHTTPLinkIsRejected() {
        let json = Self.list(url: "http://example.com")
        XCTAssertThrowsError(try ReadingLibrary.decode(Data(json.utf8))) { error in
            guard case ReadingError.insecureURL = error else { return XCTFail("got \(error)") }
        }
    }

    func testDuplicateIDIsRejected() {
        let item = Self.item(url: "https://example.com")
        let json = #"{"listVersion":1,"items":[\#(item),\#(item)]}"#
        XCTAssertThrowsError(try ReadingLibrary.decode(Data(json.utf8))) { error in
            guard case ReadingError.duplicateID = error else { return XCTFail("got \(error)") }
        }
    }

    func testUnknownKindIsRejected() {
        let json = Self.list(url: "https://example.com").replacingOccurrences(of: "\"book\"", with: "\"podcast\"")
        XCTAssertThrowsError(try ReadingLibrary.decode(Data(json.utf8)))
    }

    func testLevelsSortBeginnerFirst() {
        XCTAssertEqual([ReadingItem.Level.advanced, .beginner, .intermediate].sorted(), [.beginner, .intermediate, .advanced])
    }

    private static func item(url: String) -> String {
        #"{"id":"x","kind":"book","title":"T","authors":"A","year":2020,"url":"\#(url)","summary":"S","level":"beginner","topic":"Basics"}"#
    }

    private static func list(url: String) -> String {
        #"{"listVersion":1,"items":[\#(item(url: url))]}"#
    }
}
