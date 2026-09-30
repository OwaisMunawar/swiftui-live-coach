import Foundation
import Testing
@testable import CoachCore

@Suite("DayStamp")
struct DayStampTests {
    @Test func keyRoundTrips() {
        let stamp = DayStamp(year: 2026, month: 3, day: 8)
        #expect(stamp.key == "2026-03-08")
        #expect(DayStamp(key: stamp.key) == stamp)
    }

    @Test(arguments: ["", "2026-13-01", "2026-02", "not-a-date", "2026-02-32"])
    func rejectsMalformedKeys(_ key: String) {
        #expect(DayStamp(key: key) == nil)
    }

    @Test func sameInstantIsADifferentDayInDifferentZones() {
        // 23:30 in New York is already the next morning in London.
        let instant = Date.at(2026, 6, 1, 23, 30, in: "America/New_York")
        #expect(DayStamp(instant, calendar: .gregorian("America/New_York")) == DayStamp(year: 2026, month: 6, day: 1))
        #expect(DayStamp(instant, calendar: .gregorian("Europe/London")) == DayStamp(year: 2026, month: 6, day: 2))
    }

    @Test func steppingAcrossSpringForwardLandsOnTheNextDay() {
        // US clocks jump from 02:00 to 03:00 on 8 March 2026, a 23 hour day.
        let calendar = Calendar.gregorian("America/New_York")
        let before = DayStamp(year: 2026, month: 3, day: 7)
        #expect(before.adding(days: 1, calendar: calendar) == DayStamp(year: 2026, month: 3, day: 8))
        #expect(before.adding(days: 2, calendar: calendar) == DayStamp(year: 2026, month: 3, day: 9))
    }

    @Test func steppingSkipsADayThatNeverExisted() {
        // Samoa jumped across the date line and skipped 30 December 2011.
        let calendar = Calendar.gregorian("Pacific/Apia")
        let day = DayStamp(year: 2011, month: 12, day: 29)
        #expect(day.adding(days: 1, calendar: calendar) == DayStamp(year: 2011, month: 12, day: 31))
    }

    @Test func trailingWindowIsOldestFirstAndCrossesMonths() {
        let calendar = Calendar.gregorian("UTC")
        let window = DayStamp(year: 2026, month: 3, day: 2).trailingWindow(4, calendar: calendar)
        #expect(window.map(\.key) == ["2026-02-27", "2026-02-28", "2026-03-01", "2026-03-02"])
    }
}
