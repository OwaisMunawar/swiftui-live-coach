import Foundation

/// One day of HealthKit activity, already reduced to what the coach needs.
public struct DailyActivity: Hashable, Sendable, Identifiable {
    public var day: DayStamp
    public var steps: Int
    public var activeEnergy: Int

    public var id: DayStamp { day }

    public init(day: DayStamp, steps: Int, activeEnergy: Int) {
        self.day = day
        self.steps = steps
        self.activeEnergy = activeEnergy
    }
}
