#if canImport(HealthKit)
import CoachCore
import Foundation
import HealthKit

/// Reads step count and active energy. Read-only: the app never writes to Health.
public struct HealthKitActivityProvider: ActivityProviding {
    private let store: HKHealthStore

    private static let readTypes: Set<HKObjectType> = [
        HKQuantityType(.stepCount),
        HKQuantityType(.activeEnergyBurned),
    ]

    public init(store: HKHealthStore = HKHealthStore()) {
        self.store = store
    }

    public func access() async -> ActivityAccess {
        guard HKHealthStore.isHealthDataAvailable() else { return .unsupported }
        let status = try? await store.statusForAuthorizationRequest(toShare: [], read: Self.readTypes)
        return status == .unnecessary ? .requested : .notRequested
    }

    public func requestAccess() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        try await store.requestAuthorization(toShare: [], read: Self.readTypes)
    }

    public func dailyActivity(days: Int, now: Date, calendar: Calendar) async throws -> [DailyActivity] {
        guard HKHealthStore.isHealthDataAvailable(), days > 0 else { return [] }
        let window = DayStamp(now, calendar: calendar).trailingWindow(days, calendar: calendar)
        guard let first = window.first else { return [] }
        let start = calendar.startOfDay(for: first.noon(in: calendar))

        async let steps = totals(for: HKQuantityType(.stepCount), unit: .count(), from: start, to: now, calendar: calendar)
        async let energy = totals(for: HKQuantityType(.activeEnergyBurned), unit: .kilocalorie(), from: start, to: now, calendar: calendar)
        return ActivityBuckets.merge(steps: try await steps, energy: try await energy, window: window)
    }

    private func totals(
        for type: HKQuantityType,
        unit: HKUnit,
        from start: Date,
        to end: Date,
        calendar: Calendar
    ) async throws -> [DayStamp: Double] {
        let predicate = HKSamplePredicate.quantitySample(
            type: type,
            predicate: HKQuery.predicateForSamples(withStart: start, end: end)
        )
        let descriptor = HKStatisticsCollectionQueryDescriptor(
            predicate: predicate,
            options: .cumulativeSum,
            anchorDate: start,
            intervalComponents: DateComponents(day: 1)
        )
        let collection = try await descriptor.result(for: store)

        var result: [DayStamp: Double] = [:]
        collection.enumerateStatistics(from: start, to: end) { statistics, _ in
            if let sum = statistics.sumQuantity()?.doubleValue(for: unit) {
                result[DayStamp(statistics.startDate, calendar: calendar)] = sum
            }
        }
        return result
    }
}
#endif
