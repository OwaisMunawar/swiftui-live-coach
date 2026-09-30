import Foundation
import SwiftData

@Model
public final class Habit {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var symbolName: String
    public var tintName: String
    public var createdAt: Date
    public var sortOrder: Int

    @Relationship(deleteRule: .cascade, inverse: \HabitCompletion.habit)
    public var completions: [HabitCompletion] = []

    public init(
        id: UUID = UUID(),
        name: String,
        symbolName: String = "checkmark.circle",
        tint: HabitTint = .teal,
        createdAt: Date = .now,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.symbolName = symbolName
        self.tintName = tint.rawValue
        self.createdAt = createdAt
        self.sortOrder = sortOrder
    }

    public var tint: HabitTint {
        get { HabitTint(rawValue: tintName) ?? .teal }
        set { tintName = newValue.rawValue }
    }
}

extension Habit {
    public var completedDays: Set<DayStamp> {
        Set(completions.compactMap(\.day))
    }

    public func isCompleted(on day: DayStamp) -> Bool {
        completions.contains { $0.dayKey == day.key }
    }

    /// Marks the habit done for `day`. Idempotent, which is what Siri and
    /// Shortcuts want: saying "log water" twice should not undo it.
    public func markCompleted(on day: DayStamp, in context: ModelContext, at date: Date = .now) {
        guard !isCompleted(on: day) else { return }
        let completion = HabitCompletion(day: day, loggedAt: date)
        context.insert(completion)
        completion.habit = self
        if !completions.contains(where: { $0 === completion }) {
            completions.append(completion)
        }
    }

    /// Flips the completion for `day` and returns the new state. Used by the
    /// check buttons in the app and the interactive widget.
    @discardableResult
    public func toggle(on day: DayStamp, in context: ModelContext, at date: Date = .now) -> Bool {
        if let existing = completions.first(where: { $0.dayKey == day.key }) {
            completions.removeAll { $0 === existing }
            context.delete(existing)
            return false
        }
        markCompleted(on: day, in: context, at: date)
        return true
    }

    public func currentStreak(today: DayStamp, calendar: Calendar) -> Int {
        StreakCalculator.currentStreak(days: completedDays, today: today, calendar: calendar)
    }

    public func longestStreak(calendar: Calendar) -> Int {
        StreakCalculator.longestStreak(days: completedDays, calendar: calendar)
    }
}

public enum HabitTint: String, CaseIterable, Codable, Sendable {
    case teal, orange, pink, indigo, green, yellow
}
