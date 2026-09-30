import Foundation

public enum StreakCalculator {
    /// Consecutive completed days ending today. If today is not done yet the
    /// streak is still alive through yesterday, which matches how people think
    /// about streaks at 9am.
    public static func currentStreak(days: Set<DayStamp>, today: DayStamp, calendar: Calendar) -> Int {
        var cursor: DayStamp
        if days.contains(today) {
            cursor = today
        } else {
            let yesterday = today.adding(days: -1, calendar: calendar)
            guard days.contains(yesterday) else { return 0 }
            cursor = yesterday
        }

        var count = 0
        while days.contains(cursor) {
            count += 1
            cursor = cursor.adding(days: -1, calendar: calendar)
        }
        return count
    }

    public static func longestStreak(days: Set<DayStamp>, calendar: Calendar) -> Int {
        let sorted = days.sorted()
        guard var previous = sorted.first else { return 0 }

        var best = 1
        var run = 1
        for day in sorted.dropFirst() {
            run = previous.adding(days: 1, calendar: calendar) == day ? run + 1 : 1
            best = max(best, run)
            previous = day
        }
        return best
    }

    /// Fraction of `window` covered by `days`, in 0...1.
    public static func completionRate(days: Set<DayStamp>, window: [DayStamp]) -> Double {
        guard !window.isEmpty else { return 0 }
        let hits = window.filter(days.contains).count
        return Double(hits) / Double(window.count)
    }
}
