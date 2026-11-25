import Foundation

public struct HabitWeekStat: Hashable, Sendable {
    public var name: String
    public var completedDays: Int
    public var currentStreak: Int
    /// Check-ins the habit aims for per week, or `nil` for a daily habit.
    public var weeklyTarget: Int?

    public init(name: String, completedDays: Int, currentStreak: Int, weeklyTarget: Int? = nil) {
        self.name = name
        self.completedDays = completedDays
        self.currentStreak = currentStreak
        self.weeklyTarget = WeeklyGoal.normalized(weeklyTarget)
    }

    /// Days the habit is expected to be done within a window of `windowDays`.
    /// A habit with a weekly goal is not expected on every day.
    public func expectedDays(in windowDays: Int) -> Int {
        guard let weeklyTarget else { return windowDays }
        return min(weeklyTarget, windowDays)
    }

    /// Completed days measured against what was expected, capped at 1 so an
    /// overachieved goal cannot hide a neglected habit elsewhere.
    public func attainment(in windowDays: Int) -> Double {
        let expected = expectedDays(in: windowDays)
        guard expected > 0 else { return 1 }
        return min(Double(completedDays) / Double(expected), 1)
    }

    /// A daily habit needs attention below four days out of seven; a habit
    /// with a weekly goal as soon as it falls short of that goal.
    public func needsAttention(in windowDays: Int) -> Bool {
        if let weeklyTarget { return completedDays < min(weeklyTarget, windowDays) }
        return completedDays < 4
    }
}

/// The last seven days, flattened into plain values. This is the only input
/// the planners see, which keeps them free of SwiftData and easy to test.
public struct WeekSummary: Hashable, Sendable {
    public var days: [DayStamp]
    public var habits: [HabitWeekStat]
    public var workoutCount: Int
    public var workoutMinutes: Int
    public var averageDailySteps: Int?
    public var averageActiveEnergy: Int?

    public init(
        days: [DayStamp],
        habits: [HabitWeekStat],
        workoutCount: Int,
        workoutMinutes: Int,
        averageDailySteps: Int? = nil,
        averageActiveEnergy: Int? = nil
    ) {
        self.days = days
        self.habits = habits
        self.workoutCount = workoutCount
        self.workoutMinutes = workoutMinutes
        self.averageDailySteps = averageDailySteps
        self.averageActiveEnergy = averageActiveEnergy
    }

    /// Share of expected check-ins that happened. A habit with a weekly goal is
    /// measured against its goal, so "three a week" done three times counts as 100%.
    public var habitCompletionRate: Double {
        let window = max(days.count, 1)
        let expected = habits.map { $0.expectedDays(in: window) }.reduce(0, +)
        guard expected > 0 else { return 0 }
        let achieved = habits.map { min($0.completedDays, $0.expectedDays(in: window)) }.reduce(0, +)
        return Double(achieved) / Double(expected)
    }

    /// The habit furthest behind what it expects, among those that need attention.
    /// `nil` when every habit is on track.
    public var weakestHabit: HabitWeekStat? {
        let window = max(days.count, 1)
        return habits
            .filter { $0.needsAttention(in: window) }
            .min { lhs, rhs in
                let left = lhs.attainment(in: window)
                let right = rhs.attainment(in: window)
                return left == right ? lhs.name < rhs.name : left < right
            }
    }

    public var strongestStreak: HabitWeekStat? {
        habits.max { ($0.currentStreak, $1.name) < ($1.currentStreak, $0.name) }
    }
}

extension WeekSummary {
    public static func make(
        habits: [Habit],
        sessions: [WorkoutSession],
        activity: [DailyActivity] = [],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> WeekSummary {
        let today = DayStamp(now, calendar: calendar)
        let window = today.trailingWindow(7, calendar: calendar)
        let windowSet = Set(window)

        let stats = habits.map { habit in
            let done = habit.completedDays
            return HabitWeekStat(
                name: habit.name,
                completedDays: done.intersection(windowSet).count,
                currentStreak: StreakCalculator.currentStreak(days: done, today: today, calendar: calendar),
                weeklyTarget: habit.weeklyTarget
            )
        }

        let recent = sessions.filter { windowSet.contains(DayStamp($0.startedAt, calendar: calendar)) && !$0.isActive }
        let minutes = recent.map { $0.activeDuration(at: now) }.reduce(0, +) / 60

        // Days with zero steps usually mean "no data", not "didn't move", so
        // they are excluded from the average rather than dragging it down.
        let measured = activity.filter { windowSet.contains($0.day) && $0.steps > 0 }
        let avgSteps = measured.isEmpty ? nil : measured.map(\.steps).reduce(0, +) / measured.count
        let avgEnergy = measured.isEmpty ? nil : measured.map(\.activeEnergy).reduce(0, +) / measured.count

        return WeekSummary(
            days: window,
            habits: stats,
            workoutCount: recent.filter { $0.kind.isPhysical }.count,
            workoutMinutes: Int(minutes.rounded()),
            averageDailySteps: avgSteps,
            averageActiveEnergy: avgEnergy
        )
    }
}
