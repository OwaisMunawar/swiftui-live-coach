import Foundation
import Testing
@testable import CoachCore

@Suite("SessionClock")
struct SessionClockTests {
    let start = Date(timeIntervalSince1970: 1_000_000)

    @Test func runningClockMeasuresWallTime() {
        let clock = SessionClock(startedAt: start)
        #expect(clock.elapsed(at: start.addingTimeInterval(90)) == 90)
        #expect(clock.elapsed(at: start.addingTimeInterval(-5)) == 0)
    }

    @Test func pausedTimeIsExcluded() {
        var clock = SessionClock(startedAt: start)
        clock.pause(at: start.addingTimeInterval(60))
        #expect(clock.elapsed(at: start.addingTimeInterval(600)) == 60)

        clock.resume(at: start.addingTimeInterval(300))
        #expect(clock.pausedDuration == 240)
        #expect(clock.elapsed(at: start.addingTimeInterval(360)) == 120)
        #expect(clock.effectiveStart == start.addingTimeInterval(240))
    }

    @Test func pauseAndResumeAreIdempotent() {
        var clock = SessionClock(startedAt: start)
        clock.resume(at: start.addingTimeInterval(10))
        #expect(clock.pausedDuration == 0)

        clock.pause(at: start.addingTimeInterval(20))
        clock.pause(at: start.addingTimeInterval(50))
        #expect(clock.pausedAt == start.addingTimeInterval(20))
    }
}
