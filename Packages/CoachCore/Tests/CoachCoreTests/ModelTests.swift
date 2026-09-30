import Foundation
import SwiftData
import Testing
@testable import CoachCore

@MainActor
@Suite("SwiftData models")
struct ModelTests {
    let container: ModelContainer
    let context: ModelContext
    let calendar = Calendar.gregorian("Europe/London")

    init() throws {
        container = try CoachStore.makeContainer(inMemory: true)
        context = container.mainContext
    }

    @Test func toggleInsertsThenRemovesACompletion() throws {
        let habit = Habit(name: "Water")
        context.insert(habit)
        let day = DayStamp(year: 2026, month: 9, day: 30)

        #expect(habit.toggle(on: day, in: context))
        try context.save()
        #expect(try context.fetchCount(FetchDescriptor<HabitCompletion>()) == 1)
        #expect(habit.isCompleted(on: day))

        #expect(!habit.toggle(on: day, in: context))
        try context.save()
        #expect(try context.fetchCount(FetchDescriptor<HabitCompletion>()) == 0)
        #expect(!habit.isCompleted(on: day))
    }

    @Test func markCompletedIsIdempotent() throws {
        let habit = Habit(name: "Stretch")
        context.insert(habit)
        let day = DayStamp(year: 2026, month: 9, day: 30)
        habit.markCompleted(on: day, in: context)
        habit.markCompleted(on: day, in: context)
        try context.save()
        #expect(habit.completions.count == 1)
    }

    @Test func deletingAHabitCascadesToCompletions() throws {
        let habit = Habit(name: "Read")
        context.insert(habit)
        let today = DayStamp(year: 2026, month: 9, day: 30)
        for day in today.trailingWindow(5, calendar: calendar) {
            habit.markCompleted(on: day, in: context)
        }
        try context.save()
        #expect(habit.currentStreak(today: today, calendar: calendar) == 5)

        context.delete(habit)
        try context.save()
        #expect(try context.fetchCount(FetchDescriptor<HabitCompletion>()) == 0)
    }

    @Test func workoutSessionLifecycle() throws {
        let start = Date(timeIntervalSince1970: 2_000_000)
        let session = WorkoutSession(kind: .run, startedAt: start)
        context.insert(session)
        try context.save()
        #expect(try context.activeWorkoutSession()?.id == session.id)

        session.togglePause(at: start.addingTimeInterval(600))
        session.togglePause(at: start.addingTimeInterval(660))
        session.complete(at: start.addingTimeInterval(1_260))
        try context.save()

        #expect(session.activeDuration() == 1_200)
        #expect(try context.activeWorkoutSession() == nil)
        // Completing twice must not move the end date.
        session.complete(at: start.addingTimeInterval(9_999))
        #expect(session.endedAt == start.addingTimeInterval(1_260))
    }

    @Test func weekSummaryAggregatesHabitsWorkoutsAndSteps() throws {
        let now = Date.at(2026, 9, 30, 18, in: "Europe/London")
        let today = DayStamp(now, calendar: calendar)
        let habit = Habit(name: "Meditate")
        context.insert(habit)
        for day in today.trailingWindow(3, calendar: calendar) {
            habit.markCompleted(on: day, in: context)
        }
        // Outside the seven day window, so ignored.
        habit.markCompleted(on: today.adding(days: -20, calendar: calendar), in: context)

        let recent = WorkoutSession(kind: .strength, startedAt: now.addingTimeInterval(-86_400))
        recent.complete(at: recent.startedAt.addingTimeInterval(30 * 60))
        let focus = WorkoutSession(kind: .focus, startedAt: now.addingTimeInterval(-7_200))
        focus.complete(at: focus.startedAt.addingTimeInterval(25 * 60))
        let stale = WorkoutSession(kind: .run, startedAt: now.addingTimeInterval(-15 * 86_400))
        stale.complete(at: stale.startedAt.addingTimeInterval(40 * 60))
        [recent, focus, stale].forEach(context.insert)

        let activity = [
            DailyActivity(day: today, steps: 8_000, activeEnergy: 400),
            DailyActivity(day: today.adding(days: -1, calendar: calendar), steps: 4_000, activeEnergy: 200),
            DailyActivity(day: today.adding(days: -2, calendar: calendar), steps: 0, activeEnergy: 0),
        ]

        let summary = WeekSummary.make(habits: [habit], sessions: [recent, focus, stale], activity: activity,
                                       now: now, calendar: calendar)
        #expect(summary.days.count == 7)
        #expect(summary.habits == [HabitWeekStat(name: "Meditate", completedDays: 3, currentStreak: 3)])
        #expect(summary.workoutCount == 1)
        #expect(summary.workoutMinutes == 55)
        #expect(summary.averageDailySteps == 6_000)
        #expect(summary.averageActiveEnergy == 300)
    }

    @Test func demoSeedIsDeterministicAndLeavesTodayOpen() throws {
        let now = Date.at(2026, 9, 30, 9, in: "Europe/London")
        try DemoSeed.populate(context, now: now, calendar: calendar)
        let habits = try context.habits()
        #expect(habits.map(\.name) == DemoSeed.templates.map(\.name))

        let today = DayStamp(now, calendar: calendar)
        let water = try #require(habits.first { $0.name == "Drink 2L water" })
        #expect(water.currentStreak(today: today, calendar: calendar) == 22)
        #expect(habits.filter { $0.isCompleted(on: today) }.count == 2)

        // Running it again replaces rather than duplicates.
        try DemoSeed.populate(context, now: now, calendar: calendar)
        #expect(try context.habits().count == DemoSeed.templates.count)
    }
}
