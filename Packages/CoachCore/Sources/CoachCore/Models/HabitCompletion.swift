import Foundation
import SwiftData

@Model
public final class HabitCompletion {
    /// `yyyy-MM-dd` in the calendar the user was in when they logged it.
    public var dayKey: String
    public var loggedAt: Date
    public var habit: Habit?

    public init(day: DayStamp, loggedAt: Date = .now) {
        self.dayKey = day.key
        self.loggedAt = loggedAt
    }

    public var day: DayStamp? { DayStamp(key: dayKey) }
}
