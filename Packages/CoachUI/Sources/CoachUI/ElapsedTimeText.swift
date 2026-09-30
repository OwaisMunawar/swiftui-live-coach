import CoachCore
import SwiftUI

/// Shows a session's active time. While running it uses the system timer text,
/// which keeps ticking in widgets and Live Activities without timeline reloads.
public struct ElapsedTimeText: View {
    private let clock: SessionClock

    public init(clock: SessionClock) {
        self.clock = clock
    }

    public var body: some View {
        Group {
            if clock.isPaused {
                Text(Duration.seconds(clock.elapsed(at: .now)), format: .time(pattern: .minuteSecond(padMinuteToLength: 1)))
            } else {
                Text(timerInterval: clock.effectiveStart...Date.distantFuture, countsDown: false)
            }
        }
        .monospacedDigit()
    }
}
