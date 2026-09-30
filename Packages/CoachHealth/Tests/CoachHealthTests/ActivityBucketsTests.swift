import CoachCore
import Foundation
import Testing
@testable import CoachHealth

@Suite("Activity buckets")
struct ActivityBucketsTests {
    @Test func fillsMissingDaysWithZeroesInOrder() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        let window = DayStamp(year: 2026, month: 9, day: 30).trailingWindow(3, calendar: calendar)

        let merged = ActivityBuckets.merge(
            steps: [window[0]: 5_432.6, window[2]: 10_001],
            energy: [window[2]: 412.4],
            window: window
        )

        #expect(merged.map(\.day) == window)
        #expect(merged.map(\.steps) == [5_433, 0, 10_001])
        #expect(merged.map(\.activeEnergy) == [0, 0, 412])
    }
}
