import Foundation
import SwiftData

@Model
final class LessonCompletion {
    @Attribute(.unique) var lessonID: String
    var firstCompletedAt: Date
    var lastCompletedAt: Date
    var bestCorrect: Int
    var questionCount: Int

    init(lessonID: String, completedAt: Date, correct: Int, questionCount: Int) {
        self.lessonID = lessonID
        self.firstCompletedAt = completedAt
        self.lastCompletedAt = completedAt
        self.bestCorrect = correct
        self.questionCount = questionCount
    }
}

/// One row per local calendar day on which the user finished at least one lesson.
@Model
final class StudyDay {
    /// "yyyy-MM-dd" in the user's calendar at the time of study.
    @Attribute(.unique) var dayKey: String

    init(dayKey: String) {
        self.dayKey = dayKey
    }
}
