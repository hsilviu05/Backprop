import Foundation

/// Top-level manifest bundled at Resources/Content/manifest.json.
struct ContentManifest: Decodable, Sendable {
    let contentVersion: Int
    /// Chapters with index < freeChapterCount are free in every track.
    let freeChapterCount: Int
    let tracks: [Track]
}

struct Track: Decodable, Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let summary: String
    let systemImage: String
    let chapters: [Chapter]
}

struct Chapter: Decodable, Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let lessonIDs: [String]
}

struct Lesson: Decodable, Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let minutes: Int
    let steps: [LessonStep]

    var quizSteps: [QuizStep] {
        steps.compactMap { step -> QuizStep? in
            guard case .quiz(let quiz) = step else { return nil }
            return quiz
        }
    }
}

enum WidgetKind: String, Decodable, Hashable, Sendable {
    case linearRegression
    case gradientDescent
}

struct QuizStep: Decodable, Hashable, Sendable {
    let question: String
    let choices: [String]
    let answerIndex: Int
    let explanation: String
}

enum LessonStep: Decodable, Hashable, Sendable {
    case text(markdown: String)
    case widget(kind: WidgetKind, caption: String)
    case quiz(QuizStep)

    private enum CodingKeys: String, CodingKey {
        case type, markdown, widget, caption
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "text":
            self = .text(markdown: try container.decode(String.self, forKey: .markdown))
        case "widget":
            self = .widget(
                kind: try container.decode(WidgetKind.self, forKey: .widget),
                caption: try container.decodeIfPresent(String.self, forKey: .caption) ?? ""
            )
        case "quiz":
            let quiz = try QuizStep(from: decoder)
            guard quiz.choices.indices.contains(quiz.answerIndex) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .type, in: container,
                    debugDescription: "answerIndex \(quiz.answerIndex) out of range for \"\(quiz.question)\""
                )
            }
            self = .quiz(quiz)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type, in: container, debugDescription: "Unknown step type \"\(type)\""
            )
        }
    }
}
