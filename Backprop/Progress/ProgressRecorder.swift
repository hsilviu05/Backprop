import Foundation
import SwiftData

@MainActor
enum ProgressRecorder {
    /// Records a finished lesson and marks today as a study day. Re-taking a lesson keeps the best score.
    static func recordCompletion(
        lessonID: String,
        correct: Int,
        questionCount: Int,
        in context: ModelContext,
        now: Date = .now,
        calendar: Calendar = .current
    ) throws {
        let lessonDescriptor = FetchDescriptor<LessonCompletion>(predicate: #Predicate { $0.lessonID == lessonID })
        if let existing = try context.fetch(lessonDescriptor).first {
            existing.lastCompletedAt = now
            existing.bestCorrect = max(existing.bestCorrect, correct)
            existing.questionCount = questionCount
        } else {
            context.insert(LessonCompletion(lessonID: lessonID, completedAt: now, correct: correct, questionCount: questionCount))
        }

        let key = StreakCalculator.dayKey(for: now, calendar: calendar)
        let dayDescriptor = FetchDescriptor<StudyDay>(predicate: #Predicate { $0.dayKey == key })
        if try context.fetch(dayDescriptor).isEmpty {
            context.insert(StudyDay(dayKey: key))
        }
        try context.save()
    }
}
