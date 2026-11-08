import Foundation

/// Curated reading list bundled at Resources/Content/reading.json.
struct ReadingList: Decodable, Sendable {
    let listVersion: Int
    let items: [ReadingItem]
}

struct ReadingItem: Decodable, Identifiable, Hashable, Sendable {
    enum Kind: String, Decodable, CaseIterable, Sendable {
        case book, video, article, paper, course

        var title: String {
            switch self {
            case .book: "Books"
            case .video: "Videos"
            case .article: "Articles"
            case .paper: "Papers"
            case .course: "Courses"
            }
        }

        var systemImage: String {
            switch self {
            case .book: "book.closed"
            case .video: "play.rectangle"
            case .article: "doc.text"
            case .paper: "doc.richtext"
            case .course: "graduationcap"
            }
        }
    }

    enum Level: String, Decodable, Comparable, Sendable {
        case beginner, intermediate, advanced

        var title: String { rawValue.capitalized }

        private var rank: Int {
            switch self {
            case .beginner: 0
            case .intermediate: 1
            case .advanced: 2
            }
        }

        static func < (lhs: Level, rhs: Level) -> Bool { lhs.rank < rhs.rank }
    }

    let id: String
    let kind: Kind
    let title: String
    let authors: String
    /// Omitted for living resources (courses, continuously revised books).
    let year: Int?
    let url: URL
    let summary: String
    let level: Level
    let topic: String
    /// Print ISBN-13, used to show the cover from Open Library. Books only.
    let isbn: String?
    /// 11-character YouTube video id. Required for videos, absent otherwise.
    let youtubeID: String?

    /// Open Library cover, or nil when the book has no print edition.
    /// `default=false` makes a missing cover a 404 so we fall back to our own cover.
    var coverURL: URL? {
        isbn.flatMap { URL(string: "https://covers.openlibrary.org/b/isbn/\($0)-M.jpg?default=false") }
    }

    /// 16:9 thumbnail served by YouTube for the video.
    var thumbnailURL: URL? {
        youtubeID.flatMap { URL(string: "https://i.ytimg.com/vi/\($0)/mqdefault.jpg") }
    }
}

enum ReadingError: Error, CustomStringConvertible {
    case missingFile
    case duplicateID(String)
    case insecureURL(String)
    case emptyField(String)
    case invalidFile(String)
    case invalidVideo(String)
    case invalidISBN(String)

    var description: String {
        switch self {
        case .missingFile: "reading.json is missing from the app bundle."
        case .duplicateID(let id): "Two reading items share the id \(id)."
        case .insecureURL(let id): "Reading item \(id) must use an https link."
        case .emptyField(let id): "Reading item \(id) has an empty title, author, summary or topic."
        case .invalidFile(let detail): "reading.json is invalid: \(detail)"
        case .invalidVideo(let id): "Reading item \(id) needs a valid YouTube id and youtube.com link if, and only if, it is a video."
        case .invalidISBN(let id): "Reading item \(id) has an ISBN that is not a valid ISBN-13."
        }
    }
}

enum ReadingLibrary {
    /// Decodes and validates the list. SFSafariViewController only accepts http(s),
    /// and we require https so no page loads in the clear.
    static func decode(_ data: Data) throws -> [ReadingItem] {
        let list = try JSONDecoder().decode(ReadingList.self, from: data)
        var seen = Set<String>()
        for item in list.items {
            guard seen.insert(item.id).inserted else { throw ReadingError.duplicateID(item.id) }
            guard item.url.scheme?.lowercased() == "https", item.url.host() != nil else {
                throw ReadingError.insecureURL(item.id)
            }
            let fields = [item.title, item.authors, item.summary, item.topic]
            guard fields.allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
                throw ReadingError.emptyField(item.id)
            }
            guard isValidVideo(item) else { throw ReadingError.invalidVideo(item.id) }
            if let isbn = item.isbn, !isValidISBN13(isbn) { throw ReadingError.invalidISBN(item.id) }
        }
        return list.items
    }

    static func isValidVideo(_ item: ReadingItem) -> Bool {
        guard item.kind == .video else { return item.youtubeID == nil }
        guard let id = item.youtubeID, id.count == 11,
              id.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-" || $0 == "_") }),
              let host = item.url.host()?.lowercased(),
              host == "www.youtube.com" || host == "youtube.com" else { return false }
        // The link must point at the same video as the thumbnail.
        let query = URLComponents(url: item.url, resolvingAgainstBaseURL: false)?.queryItems
        return query?.first(where: { $0.name == "v" })?.value == id
    }

    static func isValidISBN13(_ isbn: String) -> Bool {
        let digits = isbn.compactMap(\.wholeNumberValue)
        guard digits.count == 13, isbn.count == 13 else { return false }
        let sum = digits.enumerated().reduce(0) { $0 + $1.element * ($1.offset.isMultiple(of: 2) ? 1 : 3) }
        return sum.isMultiple(of: 10)
    }

    static func loadBundled(bundle: Bundle = .main) -> Result<[ReadingItem], ReadingError> {
        guard let url = bundle.url(forResource: "reading", withExtension: "json") else {
            return .failure(.missingFile)
        }
        do {
            return .success(try decode(Data(contentsOf: url)))
        } catch let error as ReadingError {
            return .failure(error)
        } catch {
            return .failure(.invalidFile(String(describing: error)))
        }
    }
}
