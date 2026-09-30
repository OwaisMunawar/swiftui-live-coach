import Foundation

/// Pausable stopwatch state. Pure value type so the same logic drives the app,
/// the Live Activity content state and the tests.
public struct SessionClock: Codable, Hashable, Sendable {
    public var startedAt: Date
    public var pausedAt: Date?
    public var pausedDuration: TimeInterval

    public init(startedAt: Date, pausedAt: Date? = nil, pausedDuration: TimeInterval = 0) {
        self.startedAt = startedAt
        self.pausedAt = pausedAt
        self.pausedDuration = pausedDuration
    }

    public var isPaused: Bool { pausedAt != nil }

    public func elapsed(at now: Date) -> TimeInterval {
        let end = pausedAt ?? now
        return max(0, end.timeIntervalSince(startedAt) - pausedDuration)
    }

    /// The start date a running `Text(timerInterval:)` should count from so that
    /// it shows the elapsed active time.
    public var effectiveStart: Date {
        startedAt.addingTimeInterval(pausedDuration)
    }

    public mutating func pause(at now: Date) {
        guard pausedAt == nil else { return }
        pausedAt = max(now, startedAt)
    }

    public mutating func resume(at now: Date) {
        guard let pausedAt else { return }
        pausedDuration += max(0, now.timeIntervalSince(pausedAt))
        self.pausedAt = nil
    }

    public mutating func togglePause(at now: Date) {
        if isPaused {
            resume(at: now)
        } else {
            pause(at: now)
        }
    }
}
