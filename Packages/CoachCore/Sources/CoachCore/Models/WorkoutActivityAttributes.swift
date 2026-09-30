#if canImport(ActivityKit) && os(iOS)
import ActivityKit
import Foundation

/// Shared between the app (which starts and updates the activity) and the
/// widget extension (which renders it on the Lock Screen and Dynamic Island).
public struct WorkoutActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, Sendable {
        public var clock: SessionClock

        public init(clock: SessionClock) {
            self.clock = clock
        }
    }

    public var sessionID: UUID
    public var kindRaw: String

    public init(sessionID: UUID, kind: WorkoutKind) {
        self.sessionID = sessionID
        self.kindRaw = kind.rawValue
    }

    public var kind: WorkoutKind { WorkoutKind(rawValue: kindRaw) ?? .strength }
}
#endif
