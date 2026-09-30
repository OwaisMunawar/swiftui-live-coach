import Foundation

public struct HabitWeekStat: Hashable, Sendable {
    public var name: String
    public var completedDays: Int
    public var currentStreak: Int

    public init(name: String, completedDays: Int, currentStreak: Int) {
        self.name = name
        self.completedDays = completedDays
        self.currentStreak = currentStreak
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

    public var habitCompletionRate: Double {
        let possible = habits.count * max(days.count, 1)
        guard possible > 0 else { return 0 }
        return Double(habits.map(\.completedDays).reduce(0, +)) / Double(possible)
    }

    public var weakestHabit: HabitWeekStat? {
        habits.min { ($0.completedDays, $0.name) < ($1.completedDays, $1.name) }
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
                currentStreak: StreakCalculator.currentStreak(days: done, today: today, calendar: calendar)
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
