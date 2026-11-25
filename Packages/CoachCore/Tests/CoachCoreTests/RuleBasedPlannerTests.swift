import Foundation
import Testing
@testable import CoachCore

@Suite("Rule-based planner")
struct RuleBasedPlannerTests {
    // Wednesday 30 September 2026, 09:00 UTC.
    let now = Date.at(2026, 9, 30, 9, in: "UTC")
    var planner: RuleBasedPlanner {
        let now = now
        return RuleBasedPlanner(calendar: .gregorian("UTC"), now: { now })
    }

    func summary(workouts: Int, minutes: Int, steps: Int? = nil, habits: [HabitWeekStat] = []) -> WeekSummary {
        let days = DayStamp(now, calendar: .gregorian("UTC")).trailingWindow(7, calendar: .gregorian("UTC"))
        return WeekSummary(days: days, habits: habits, workoutCount: workouts, workoutMinutes: minutes,
                           averageDailySteps: steps)
    }

    @Test func inactiveWeekGetsAGentleRestart() {
        let plan = planner.plan(for: summary(workouts: 0, minutes: 0))
        #expect(plan.source == .ruleBased)
        #expect(plan.sessions.count == 3)
        #expect(plan.sessions.allSatisfy { $0.minutes <= 20 })
        #expect(plan.sessions.first?.weekday == "Thursday")
    }

    @Test func activeWeekProgressesDurationByAboutTenPercent() {
        let plan = planner.plan(for: summary(workouts: 4, minutes: 160))
        let strength = plan.sessions.filter { $0.kind == .strength }
        #expect(plan.headline == "Keep the momentum")
        #expect(strength.count == 2)
        #expect(strength.allSatisfy { $0.minutes == 44 })
    }

    @Test func lowStepsAddsAWalkAndWeakHabitAddsAFocusBlock() {
        let habits = [
            HabitWeekStat(name: "Read", completedDays: 2, currentStreak: 0),
            HabitWeekStat(name: "Water", completedDays: 7, currentStreak: 9),
        ]
        let plan = planner.plan(for: summary(workouts: 1, minutes: 30, steps: 4_200, habits: habits))
        #expect(plan.sessions.contains { $0.kind == .walk && $0.minutes == 40 })
        #expect(plan.sessions.contains { $0.kind == .focus && $0.title == "Protect read" })
        #expect(plan.summary.contains("Water is on a 9-day streak"))
    }

    @Test func neverExceedsTheSessionCap() {
        let habits = [HabitWeekStat(name: "Stretch", completedDays: 0, currentStreak: 0)]
        let plan = planner.plan(for: summary(workouts: 6, minutes: 300, steps: 1_000, habits: habits))
        #expect(plan.sessions.count == RuleBasedPlanner.maxSessions)
        #expect(plan.sessions.allSatisfy { $0.minutes <= 75 })
    }

    @Test func aMetWeeklyGoalIsNotFlaggedAsWeak() {
        let habits = [
            HabitWeekStat(name: "Run", completedDays: 3, currentStreak: 0, weeklyTarget: 3),
            HabitWeekStat(name: "Water", completedDays: 7, currentStreak: 9),
        ]
        let week = summary(workouts: 3, minutes: 120, steps: 9_000, habits: habits)
        #expect(week.weakestHabit == nil)
        #expect(week.habitCompletionRate == 1)
        #expect(!planner.plan(for: week).sessions.contains { $0.kind == .focus })
    }

    @Test func aMissedWeeklyGoalIsFlaggedWithItsGoal() {
        let habits = [
            HabitWeekStat(name: "Run", completedDays: 1, currentStreak: 0, weeklyTarget: 3),
            HabitWeekStat(name: "Water", completedDays: 5, currentStreak: 2),
        ]
        let week = summary(workouts: 3, minutes: 120, steps: 9_000, habits: habits)
        #expect(week.weakestHabit?.name == "Run")
        let focus = planner.plan(for: week).sessions.first { $0.kind == .focus }
        #expect(focus?.rationale.contains("Goal is 3 a week") == true)
    }

    @Test func weakestHabitIsChosenByShortfallNotRawDays() {
        // 2 of 3 is a better week than 2 of 7, even though the raw count matches.
        let habits = [
            HabitWeekStat(name: "Read", completedDays: 2, currentStreak: 0),
            HabitWeekStat(name: "Run", completedDays: 2, currentStreak: 0, weeklyTarget: 3),
        ]
        #expect(summary(workouts: 3, minutes: 120, habits: habits).weakestHabit?.name == "Read")
    }

    @Test func overachievingAGoalDoesNotInflateTheRate() {
        let habits = [
            HabitWeekStat(name: "Run", completedDays: 6, currentStreak: 0, weeklyTarget: 3),
            HabitWeekStat(name: "Read", completedDays: 0, currentStreak: 0),
        ]
        // 3 expected + 7 expected = 10; capped achievement 3 + 0 = 3.
        #expect(summary(workouts: 1, minutes: 30, habits: habits).habitCompletionRate == 0.3)
    }
}
