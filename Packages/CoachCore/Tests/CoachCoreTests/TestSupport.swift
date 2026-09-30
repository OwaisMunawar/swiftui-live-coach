import Foundation
@testable import CoachCore

extension Calendar {
    static func gregorian(_ identifier: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        // A bad identifier is a bug in the test itself.
        calendar.timeZone = TimeZone(identifier: identifier)! // swiftlint:disable:this force_unwrapping
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }
}

extension Date {
    /// Builds an absolute instant from wall-clock components in `zone`.
    static func at(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0, in zone: String) -> Date {
        let calendar = Calendar.gregorian(zone)
        let parts = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
        return calendar.date(from: parts)! // swiftlint:disable:this force_unwrapping
    }
}

extension DayStamp {
    /// Consecutive days ending on `self`, oldest first.
    func run(_ length: Int, calendar: Calendar) -> Set<DayStamp> {
        Set(trailingWindow(length, calendar: calendar))
    }
}
