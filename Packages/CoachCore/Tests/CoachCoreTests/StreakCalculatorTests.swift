import Foundation
import Testing
@testable import CoachCore

@Suite("Streaks")
struct StreakCalculatorTests {
    let utc = Calendar.gregorian("UTC")

    @Test func emptyHistoryHasNoStreak() {
        let today = DayStamp(year: 2026, month: 9, day: 30)
        #expect(StreakCalculator.currentStreak(days: [], today: today, calendar: utc) == 0)
        #expect(StreakCalculator.longestStreak(days: [], calendar: utc) == 0)
    }

    @Test func streakIncludingToday() {
        let today = DayStamp(year: 2026, month: 9, day: 30)
        let days = today.run(5, calendar: utc)
        #expect(StreakCalculator.currentStreak(days: days, today: today, calendar: utc) == 5)
    }

    @Test func streakSurvivesUntilTodayIsLogged() {
        let today = DayStamp(year: 2026, month: 9, day: 30)
        let days = today.adding(days: -1, calendar: utc).run(3, calendar: utc)
        #expect(StreakCalculator.currentStreak(days: days, today: today, calendar: utc) == 3)
    }

    @Test func missingYesterdayBreaksTheStreak() {
        let today = DayStamp(year: 2026, month: 9, day: 30)
        let days = today.adding(days: -2, calendar: utc).run(10, calendar: utc)
        #expect(StreakCalculator.currentStreak(days: days, today: today, calendar: utc) == 0)
        #expect(StreakCalculator.longestStreak(days: days, calendar: utc) == 10)
    }

    @Test func longestStreakPicksTheBestRun() {
        let end = DayStamp(year: 2026, month: 9, day: 30)
        let recent = end.run(3, calendar: utc)
        let older = end.adding(days: -10, calendar: utc).run(6, calendar: utc)
        #expect(StreakCalculator.longestStreak(days: recent.union(older), calendar: utc) == 6)
    }

    @Test(arguments: ["America/New_York", "Europe/London", "Australia/Sydney", "America/Sao_Paulo"])
    func streakIsUnbrokenAcrossDSTTransitions(zone: String) {
        // Each window straddles a DST change in at least one hemisphere in 2026.
        let calendar = Calendar.gregorian(zone)
        for today in [DayStamp(year: 2026, month: 3, day: 12), DayStamp(year: 2026, month: 4, day: 8),
                      DayStamp(year: 2026, month: 10, day: 8), DayStamp(year: 2026, month: 11, day: 5)] {
            let days = today.run(14, calendar: calendar)
            #expect(StreakCalculator.currentStreak(days: days, today: today, calendar: calendar) == 14)
        }
    }

    @Test func travellingEastDoesNotBreakTheStreak() {
        // Logged at 21:00 each evening in New York, then the user flies to
        // Tokyo. The stored day stamps are what the user saw, so the streak
        // continues even though the instants are 14 hours apart.
        let ny = Calendar.gregorian("America/New_York")
        let tokyo = Calendar.gregorian("Asia/Tokyo")
        var days: Set<DayStamp> = []
        for day in 1...4 {
            days.insert(DayStamp(Date.at(2026, 5, day, 21, in: "America/New_York"), calendar: ny))
        }
        days.insert(DayStamp(Date.at(2026, 5, 5, 20, in: "Asia/Tokyo"), calendar: tokyo))

        let today = DayStamp(Date.at(2026, 5, 5, 22, in: "Asia/Tokyo"), calendar: tokyo)
        #expect(StreakCalculator.currentStreak(days: days, today: today, calendar: tokyo) == 5)
    }

    @Test func completionRateCountsOnlyTheWindow() {
        let today = DayStamp(year: 2026, month: 9, day: 30)
        let window = today.trailingWindow(7, calendar: utc)
        let days: Set<DayStamp> = [window[0], window[3], window[6], today.adding(days: -30, calendar: utc)]
        #expect(StreakCalculator.completionRate(days: days, window: window) == 3.0 / 7.0)
        #expect(StreakCalculator.completionRate(days: days, window: []) == 0)
    }
}
