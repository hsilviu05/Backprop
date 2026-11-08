import Foundation

/// Curated reading list bundled at Resources/Content/reading.json.
struct ReadingList: Decodable, Sendable {
    let listVersion: Int
    let items: [ReadingItem]
}

struct ReadingItem: Decodable, Identifiable, Hashable, Sendable {
    enum Kind: String, Decodable, CaseIterable, Sendable {
        case book, article, paper, course

        var title: String {
            switch self {
            case .book: "Books"
            case .article: "Articles"
            case .paper: "Papers"
            case .course: "Courses"
            }
        }

        var systemImage: String {
            switch self {
            case .book: "book.closed"
            case .article: "doc.text"
            case .paper: "doc.richtext"
            case .course: "play.rectangle"
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
}

enum ReadingError: Error, CustomStringConvertible {
    case missingFile
    case duplicateID(String)
    case insecureURL(String)
    case emptyField(String)
    case invalidFile(String)

    var description: String {
        switch self {
        case .missingFile: "reading.json is missing from the app bundle."
        case .duplicateID(let id): "Two reading items share the id \(id)."
        case .insecureURL(let id): "Reading item \(id) must use an https link."
        case .emptyField(let id): "Reading item \(id) has an empty title, author, summary or topic."
        case .invalidFile(let detail): "reading.json is invalid: \(detail)"
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
        }
        return list.items
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
