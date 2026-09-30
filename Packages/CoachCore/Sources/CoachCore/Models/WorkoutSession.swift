import Foundation
import SwiftData

@Model
public final class WorkoutSession {
    @Attribute(.unique) public var id: UUID
    public var kindRaw: String
    public var startedAt: Date
    public var pausedAt: Date?
    public var pausedDuration: TimeInterval
    public var endedAt: Date?

    public init(id: UUID = UUID(), kind: WorkoutKind, startedAt: Date = .now) {
        self.id = id
        self.kindRaw = kind.rawValue
        self.startedAt = startedAt
        self.pausedDuration = 0
    }

    public var kind: WorkoutKind {
        get { WorkoutKind(rawValue: kindRaw) ?? .strength }
        set { kindRaw = newValue.rawValue }
    }

    public var isActive: Bool { endedAt == nil }

    public var clock: SessionClock {
        get { SessionClock(startedAt: startedAt, pausedAt: pausedAt, pausedDuration: pausedDuration) }
        set {
            startedAt = newValue.startedAt
            pausedAt = newValue.pausedAt
            pausedDuration = newValue.pausedDuration
        }
    }

    public func activeDuration(at now: Date = .now) -> TimeInterval {
        clock.elapsed(at: endedAt ?? now)
    }

    public func togglePause(at now: Date = .now) {
        guard isActive else { return }
        clock.togglePause(at: now)
    }

    public func complete(at now: Date = .now) {
        guard isActive else { return }
        var final = clock
        final.resume(at: now)
        clock = final
        endedAt = now
    }
}
