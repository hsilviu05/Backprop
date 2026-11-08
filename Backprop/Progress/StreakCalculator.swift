import Foundation

enum StreakCalculator {
    static func dayKey(for date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    /// Consecutive study days ending today. If today has no study yet, a streak
    /// that ended yesterday is still alive and is counted.
    static func currentStreak(studyDays: Set<String>, now: Date, calendar: Calendar) -> Int {
        guard !studyDays.isEmpty else { return 0 }
        var cursor = calendar.startOfDay(for: now)
        if !studyDays.contains(dayKey(for: cursor, calendar: calendar)) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor) else { return 0 }
            cursor = yesterday
        }
        var streak = 0
        while studyDays.contains(dayKey(for: cursor, calendar: calendar)) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    static func hasStudied(on date: Date, studyDays: Set<String>, calendar: Calendar) -> Bool {
        studyDays.contains(dayKey(for: date, calendar: calendar))
    }
}

enum XP {
    static let perLesson = 10
    static let perCorrectAnswer = 2

    static func total(for completions: [LessonCompletion]) -> Int {
        completions.reduce(0) { $0 + perLesson + $1.bestCorrect * perCorrectAnswer }
    }
}
