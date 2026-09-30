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
