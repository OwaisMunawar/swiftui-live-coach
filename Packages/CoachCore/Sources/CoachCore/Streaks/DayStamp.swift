import Foundation

/// A calendar day as the user experienced it, independent of time zone.
///
/// Completions are stored as a `DayStamp` captured in the user's calendar at the
/// moment they logged the habit. Streaks are then computed on these stamps, so a
/// flight from New York to London or a DST transition never splits or merges days.
public struct DayStamp: Hashable, Comparable, Codable, Sendable, CustomStringConvertible {
    public let year: Int
    public let month: Int
    public let day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    public init(_ date: Date, calendar: Calendar = .current) {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        self.init(year: parts.year ?? 1970, month: parts.month ?? 1, day: parts.day ?? 1)
    }

    /// Parses the `yyyy-MM-dd` form produced by `key`.
    public init?(key: String) {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3, (1...12).contains(parts[1]), (1...31).contains(parts[2]) else { return nil }
        self.init(year: parts[0], month: parts[1], day: parts[2])
    }

    /// Stable, sortable storage key, e.g. `2026-03-08`.
    public var key: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    public var description: String { key }

    /// Noon on this day. Noon is used as the anchor because some zones skip or
    /// repeat midnight during DST changes, but no zone skips noon.
    public func noon(in calendar: Calendar) -> Date {
        let parts = DateComponents(year: year, month: month, day: day, hour: 12)
        return calendar.date(from: parts) ?? Date(timeIntervalSince1970: 0)
    }

    /// Steps by whole calendar days. Days that do not exist in `calendar`
    /// (Samoa, 30 Dec 2011) are skipped by Foundation's calendar arithmetic.
    public func adding(days: Int, calendar: Calendar) -> DayStamp {
        let anchor = noon(in: calendar)
        guard let moved = calendar.date(byAdding: .day, value: days, to: anchor) else { return self }
        return DayStamp(moved, calendar: calendar)
    }

    public static func < (lhs: DayStamp, rhs: DayStamp) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }
}

extension DayStamp {
    /// The `length` days ending on (and including) `self`, oldest first.
    public func trailingWindow(_ length: Int, calendar: Calendar) -> [DayStamp] {
        guard length >= 1 else { return [] }
        return (0..<length).reversed().map { adding(days: -$0, calendar: calendar) }
    }
}

extension DayStamp {
    /// The first day of the calendar week containing `self`. Which weekday that
    /// is follows `calendar.firstWeekday`, so a Monday-first locale and a
    /// Sunday-first locale disagree about the same date, as they should.
    public func startOfWeek(calendar: Calendar) -> DayStamp {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: noon(in: calendar)) else { return self }
        // A DST change at midnight can push the interval start to 01:00, which is
        // still the same calendar day.
        return DayStamp(interval.start, calendar: calendar)
    }

    /// The seven days of the calendar week containing `self`, oldest first.
    public func weekDays(calendar: Calendar) -> [DayStamp] {
        let start = startOfWeek(calendar: calendar)
        return (0..<7).map { start.adding(days: $0, calendar: calendar) }
    }
}
