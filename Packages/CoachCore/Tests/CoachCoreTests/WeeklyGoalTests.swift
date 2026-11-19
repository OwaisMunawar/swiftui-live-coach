import Foundation
import Testing
@testable import CoachCore

@Suite("Weekly goals")
struct WeeklyGoalTests {
    /// Sunday-first, as in the US.
    let sundayFirst = Calendar.gregorian("UTC")

    /// Monday-first, as in most of Europe.
    var mondayFirst: Calendar {
        var calendar = Calendar.gregorian("UTC")
        calendar.firstWeekday = 2
        return calendar
    }

    // 2026-09-30 is a Wednesday.
    let wednesday = DayStamp(year: 2026, month: 9, day: 30)

    @Test func weekStartFollowsTheCalendarsFirstWeekday() {
        #expect(wednesday.startOfWeek(calendar: sundayFirst) == DayStamp(year: 2026, month: 9, day: 27))
        #expect(wednesday.startOfWeek(calendar: mondayFirst) == DayStamp(year: 2026, month: 9, day: 28))
    }

    @Test func weekDaysAreSevenConsecutiveDaysOldestFirst() {
        let days = wednesday.weekDays(calendar: mondayFirst)
        #expect(days.map(\.key) == [
            "2026-09-28", "2026-09-29", "2026-09-30", "2026-10-01", "2026-10-02", "2026-10-03", "2026-10-04",
        ])
    }

    @Test func weekCrossesTheNewYear() {
        let days = DayStamp(year: 2026, month: 1, day: 1).weekDays(calendar: mondayFirst)
        #expect(days.first == DayStamp(year: 2025, month: 12, day: 29))
        #expect(days.last == DayStamp(year: 2026, month: 1, day: 4))
    }

    @Test(arguments: ["America/New_York", "Europe/London", "Australia/Sydney", "America/Sao_Paulo", "Pacific/Apia"])
    func weekHasSevenDistinctDaysAcrossDSTAndDateLineChanges(zone: String) {
        let calendar = Calendar.gregorian(zone)
        for day in [DayStamp(year: 2026, month: 3, day: 8), DayStamp(year: 2026, month: 4, day: 5),
                    DayStamp(year: 2026, month: 10, day: 4), DayStamp(year: 2026, month: 11, day: 1)] {
            let week = day.weekDays(calendar: calendar)
            #expect(Set(week).count == 7)
            #expect(week.contains(day))
        }
    }

    @Test func progressCountsOnlyDaysInTheCurrentWeek() {
        let days: Set<DayStamp> = [
            DayStamp(year: 2026, month: 9, day: 26), // previous week
            DayStamp(year: 2026, month: 9, day: 28),
            DayStamp(year: 2026, month: 9, day: 30),
        ]
        let progress = WeeklyGoal.progress(days: days, target: 3, today: wednesday, calendar: mondayFirst)
        #expect(progress.completed == 2)
        #expect(progress.remaining == 1)
        #expect(!progress.isMet)
    }

    @Test func daysLeftCountsTodayThroughTheEndOfTheWeek() {
        let monday = WeeklyGoal.progress(days: [], target: 3, today: DayStamp(year: 2026, month: 9, day: 28), calendar: mondayFirst)
        let sunday = WeeklyGoal.progress(days: [], target: 3, today: DayStamp(year: 2026, month: 10, day: 4), calendar: mondayFirst)
        #expect(monday.daysLeft == 7)
        #expect(sunday.daysLeft == 1)
    }

    @Test func aGoalBecomesUnreachableOnceTooFewDaysRemain() {
        let saturday = DayStamp(year: 2026, month: 10, day: 3)
        let behind = WeeklyGoal.progress(days: [], target: 3, today: saturday, calendar: mondayFirst)
        #expect(!behind.isReachable)
        let tuesday: Set<DayStamp> = [DayStamp(year: 2026, month: 9, day: 29)]
        let oneDone = WeeklyGoal.progress(days: tuesday, target: 3, today: saturday, calendar: mondayFirst)
        #expect(oneDone.isReachable) // two left, two days remain
    }

    @Test func aMetGoalStaysReachableOnTheLastDay() {
        let sunday = DayStamp(year: 2026, month: 10, day: 4)
        let days: Set<DayStamp> = [DayStamp(year: 2026, month: 9, day: 28), DayStamp(year: 2026, month: 9, day: 30), sunday]
        let progress = WeeklyGoal.progress(days: days, target: 3, today: sunday, calendar: mondayFirst)
        #expect(progress.isMet && progress.isReachable)
    }

    @Test func streakCountsConsecutiveMetWeeks() {
        // Three completed weeks of two check-ins, Monday-first, then an empty current week.
        let weekStarts = [DayStamp(year: 2026, month: 9, day: 7), DayStamp(year: 2026, month: 9, day: 14),
                          DayStamp(year: 2026, month: 9, day: 21)]
        var days: Set<DayStamp> = []
        for start in weekStarts {
            days.insert(start)
            days.insert(start.adding(days: 3, calendar: mondayFirst))
        }
        let streak = WeeklyGoal.currentStreak(days: days, target: 2, today: wednesday, calendar: mondayFirst)
        #expect(streak == 3)
    }

    @Test func aWeekInProgressDoesNotBreakTheStreakButCountsOnceMet() {
        let lastWeek: Set<DayStamp> = [DayStamp(year: 2026, month: 9, day: 21), DayStamp(year: 2026, month: 9, day: 23)]
        #expect(WeeklyGoal.currentStreak(days: lastWeek, target: 2, today: wednesday, calendar: mondayFirst) == 1)

        let thisWeekToo = lastWeek.union([DayStamp(year: 2026, month: 9, day: 28), DayStamp(year: 2026, month: 9, day: 30)])
        #expect(WeeklyGoal.currentStreak(days: thisWeekToo, target: 2, today: wednesday, calendar: mondayFirst) == 2)
    }

    @Test func aMissedWeekEndsTheRun() {
        // Met the week of 14 Sep and 28 Sep, but not 21 Sep in between.
        let days: Set<DayStamp> = [
            DayStamp(year: 2026, month: 9, day: 14), DayStamp(year: 2026, month: 9, day: 15),
            DayStamp(year: 2026, month: 9, day: 21),
            DayStamp(year: 2026, month: 9, day: 28), DayStamp(year: 2026, month: 9, day: 29),
        ]
        #expect(WeeklyGoal.currentStreak(days: days, target: 2, today: wednesday, calendar: mondayFirst) == 1)
    }

    @Test func noHistoryMeansNoStreakAndTerminates() {
        #expect(WeeklyGoal.currentStreak(days: [], target: 3, today: wednesday, calendar: mondayFirst) == 0)
    }

    @Test func weekBoundaryDependsOnFirstWeekday() {
        // Sunday 27 Sep and Monday 28 Sep: one week for a Sunday-first calendar, two for Monday-first.
        let days: Set<DayStamp> = [DayStamp(year: 2026, month: 9, day: 27), DayStamp(year: 2026, month: 9, day: 28)]
        let sundayWeek = WeeklyGoal.progress(days: days, target: 2, today: wednesday, calendar: sundayFirst)
        let mondayWeek = WeeklyGoal.progress(days: days, target: 2, today: wednesday, calendar: mondayFirst)
        #expect(sundayWeek.isMet)
        #expect(!mondayWeek.isMet)
    }

    @Test(arguments: [(nil, nil), (0, 1), (1, 1), (3, 3), (6, 6), (7, nil), (12, nil), (-2, 1)] as [(Int?, Int?)])
    func normalizingKeepsGoalsInsideTheOfferedRange(input: Int?, expected: Int?) {
        #expect(WeeklyGoal.normalized(input) == expected)
    }
}
