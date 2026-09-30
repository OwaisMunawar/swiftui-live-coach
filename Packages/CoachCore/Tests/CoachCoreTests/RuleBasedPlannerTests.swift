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
}
