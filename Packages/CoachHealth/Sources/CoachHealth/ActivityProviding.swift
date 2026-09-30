import CoachCore
import Foundation

public enum ActivityAccess: Equatable, Sendable {
    /// Health data doesn't exist on this device (iPad without Health, Mac).
    case unsupported
    /// We have not asked yet; show a "Connect" affordance.
    case notRequested
    /// The permission sheet has been shown. HealthKit deliberately doesn't say
    /// whether read access was granted, so "requested" is all we can know.
    case requested
}

public protocol ActivityProviding: Sendable {
    func access() async -> ActivityAccess
    func requestAccess() async throws
    /// Daily totals for the `days` days ending today, oldest first. Days with
    /// no samples are returned as zeroes rather than omitted.
    func dailyActivity(days: Int, now: Date, calendar: Calendar) async throws -> [DailyActivity]
}

/// Deterministic provider for SwiftUI previews and tests.
public struct StaticActivityProvider: ActivityProviding {
    public var result: [DailyActivity]
    public var accessState: ActivityAccess

    public init(result: [DailyActivity], access: ActivityAccess = .requested) {
        self.result = result
        self.accessState = access
    }

    public func access() async -> ActivityAccess { accessState }
    public func requestAccess() async throws {}
    public func dailyActivity(days: Int, now: Date, calendar: Calendar) async throws -> [DailyActivity] {
        result
    }
}

enum ActivityBuckets {
    /// Zips per-day totals into a dense, ordered series.
    static func merge(
        steps: [DayStamp: Double],
        energy: [DayStamp: Double],
        window: [DayStamp]
    ) -> [DailyActivity] {
        window.map { day in
            DailyActivity(
                day: day,
                steps: Int((steps[day] ?? 0).rounded()),
                activeEnergy: Int((energy[day] ?? 0).rounded())
            )
        }
    }
}
