import Foundation

/// Where a habit stands against its "N days a week" goal for one calendar week.
public struct WeeklyProgress: Hashable, Sendable {
    public let target: Int
    public let completed: Int
    /// Days still available this week, counting today.
    public let daysLeft: Int

    public init(target: Int, completed: Int, daysLeft: Int) {
        self.target = target
        self.completed = completed
        self.daysLeft = daysLeft
    }

    public var isMet: Bool { completed >= target }
    public var remaining: Int { max(target - completed, 0) }

    /// False once there are fewer days left than check-ins still needed. The UI
    /// uses this to say "missed" instead of showing a goal that can no longer be met.
    public var isReachable: Bool { isMet || remaining <= daysLeft }
}

/// Weekly targets for habits that are not meant to happen every day, such as
/// "run three times a week". Pure functions over day stamps, like `StreakCalculator`.
public enum WeeklyGoal {
    /// A goal of seven is the same as a daily habit, so it is not offered.
    public static let targets = 1...6

    /// Keeps stored or user-supplied values inside `targets`. `nil` means no
    /// weekly goal, and a value that would mean "every day" is treated the same.
    public static func normalized(_ target: Int?) -> Int? {
        guard let target, target < 7 else { return nil }
        return max(target, targets.lowerBound)
    }

    public static func progress(
        days: Set<DayStamp>,
        target: Int,
        today: DayStamp,
        calendar: Calendar
    ) -> WeeklyProgress {
        let week = today.weekDays(calendar: calendar)
        let completed = week.filter(days.contains).count
        let daysLeft = week.count - (week.firstIndex(of: today) ?? 0)
        return WeeklyProgress(target: target, completed: completed, daysLeft: daysLeft)
    }

    /// Consecutive calendar weeks in which the goal was met. A week still in
    /// progress neither counts nor breaks the run until it is met, mirroring how
    /// `StreakCalculator` treats a day that is not done yet.
    public static func currentStreak(
        days: Set<DayStamp>,
        target: Int,
        today: DayStamp,
        calendar: Calendar
    ) -> Int {
        guard target >= 1 else { return 0 }
        var weekStart = today.startOfWeek(calendar: calendar)
        var count = 0

        if met(days, weekStart: weekStart, target: target, calendar: calendar) {
            count += 1
        }
        while true {
            weekStart = weekStart.adding(days: -7, calendar: calendar).startOfWeek(calendar: calendar)
            guard met(days, weekStart: weekStart, target: target, calendar: calendar) else { return count }
            count += 1
        }
    }

    private static func met(_ days: Set<DayStamp>, weekStart: DayStamp, target: Int, calendar: Calendar) -> Bool {
        weekStart.weekDays(calendar: calendar).filter(days.contains).count >= target
    }
}
