import Foundation
import Observation

/// Drives one run through a lesson's steps and scores its quiz questions.
@Observable
final class LessonSession {
    let lesson: Lesson
    private(set) var stepIndex = 0
    /// Selected choice per quiz step, keyed by step index.
    private(set) var selections: [Int: Int] = [:]

    init(lesson: Lesson) {
        self.lesson = lesson
    }

    var currentStep: LessonStep? {
        lesson.steps.indices.contains(stepIndex) ? lesson.steps[stepIndex] : nil
    }

    var isFinished: Bool { stepIndex >= lesson.steps.count }

    var progress: Double {
        lesson.steps.isEmpty ? 1 : Double(min(stepIndex, lesson.steps.count)) / Double(lesson.steps.count)
    }

    /// A quiz step must be answered before moving on; other steps can always advance.
    var canAdvance: Bool {
        guard let step = currentStep else { return false }
        if case .quiz = step { return selections[stepIndex] != nil }
        return true
    }

    func select(choice: Int) {
        guard case .quiz(let quiz) = currentStep,
              selections[stepIndex] == nil,
              quiz.choices.indices.contains(choice) else { return }
        selections[stepIndex] = choice
    }

    func selection(at index: Int) -> Int? { selections[index] }

    func advance() {
        guard canAdvance else { return }
        stepIndex += 1
    }

    var correctCount: Int {
        lesson.steps.enumerated().reduce(0) { count, pair in
            guard case .quiz(let quiz) = pair.element, selections[pair.offset] == quiz.answerIndex else { return count }
            return count + 1
        }
    }

    var questionCount: Int { lesson.quizSteps.count }
}
