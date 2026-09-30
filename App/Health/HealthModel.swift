import CoachCore
import CoachHealth
import Foundation
import Observation
import OSLog

@MainActor
@Observable
final class HealthModel {
    enum State: Equatable {
        case unknown
        case unsupported
        case needsAccess
        case loading
        case loaded([DailyActivity])
        case failed(String)
    }

    private(set) var state: State = .unknown
    private let provider: any ActivityProviding

    init(provider: any ActivityProviding) {
        self.provider = provider
    }

    /// Last seven days, or empty when nothing has been loaded.
    var week: [DailyActivity] {
        if case .loaded(let days) = state { days } else { [] }
    }

    func refresh() async {
        switch await provider.access() {
        case .unsupported:
            state = .unsupported
        case .notRequested:
            state = .needsAccess
        case .requested:
            await load()
        }
    }

    func connect() async {
        do {
            try await provider.requestAccess()
            await load()
        } catch {
            Logger.health.error("Authorization failed: \(error.localizedDescription)")
            state = .failed("Couldn't connect to Apple Health.")
        }
    }

    private func load() async {
        if week.isEmpty { state = .loading }
        do {
            state = .loaded(try await provider.dailyActivity(days: 7, now: .now, calendar: .current))
        } catch {
            Logger.health.error("Query failed: \(error.localizedDescription)")
            state = .failed("Couldn't read activity from Apple Health.")
        }
    }
}
