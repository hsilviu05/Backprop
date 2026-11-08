import XCTest
@testable import Backprop

final class StreakCalculatorTests: XCTestCase {
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Bucharest")!
        return calendar
    }()

    private func date(_ y: Int, _ m: Int, _ d: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: hour))!
    }

    private func keys(_ dates: [Date]) -> Set<String> {
        Set(dates.map { StreakCalculator.dayKey(for: $0, calendar: calendar) })
    }

    func testEmptyIsZero() {
        XCTAssertEqual(StreakCalculator.currentStreak(studyDays: [], now: date(2026, 11, 8), calendar: calendar), 0)
    }

    func testConsecutiveDaysIncludingToday() {
        let days = keys([date(2026, 11, 6), date(2026, 11, 7), date(2026, 11, 8)])
        XCTAssertEqual(StreakCalculator.currentStreak(studyDays: days, now: date(2026, 11, 8), calendar: calendar), 3)
    }

    func testStreakEndingYesterdayIsStillAlive() {
        let days = keys([date(2026, 11, 6), date(2026, 11, 7)])
        XCTAssertEqual(StreakCalculator.currentStreak(studyDays: days, now: date(2026, 11, 8, hour: 9), calendar: calendar), 2)
    }

    func testGapBreaksStreak() {
        let days = keys([date(2026, 11, 4), date(2026, 11, 5)])
        XCTAssertEqual(StreakCalculator.currentStreak(studyDays: days, now: date(2026, 11, 8), calendar: calendar), 0)
    }

    func testAcrossMonthAndDSTBoundary() {
        // Romania leaves DST on 2026-10-25.
        let days = keys([date(2026, 10, 24), date(2026, 10, 25), date(2026, 10, 26)])
        XCTAssertEqual(StreakCalculator.currentStreak(studyDays: days, now: date(2026, 10, 26, hour: 23), calendar: calendar), 3)
    }

    func testDayKeyFormat() {
        XCTAssertEqual(StreakCalculator.dayKey(for: date(2026, 1, 5), calendar: calendar), "2026-01-05")
    }
}
