import CoachCore
import CoachIntelligence
import Foundation
import Observation

@MainActor
@Observable
final class CoachModel {
    enum State: Equatable {
        case idle
        case generating
        case ready(PlanOutcome)
        case failed
    }

    private(set) var state: State = .idle
    private let planner: CoachPlanner
    private var generation: Task<Void, Never>?

    init(planner: CoachPlanner) {
        self.planner = planner
    }

    var availability: PlannerAvailability { planner.currentAvailability }

    var outcome: PlanOutcome? {
        if case .ready(let outcome) = state { outcome } else { nil }
    }

    /// Cancels any in-flight generation so rapid refreshes never race.
    func generate(for summary: WeekSummary) async {
        generation?.cancel()
        state = .generating
        let planner = planner
        let task = Task {
            do {
                let outcome = try await planner.makePlan(for: summary)
                guard !Task.isCancelled else { return }
                state = .ready(outcome)
            } catch {
                guard !Task.isCancelled else { return }
                state = .failed
            }
        }
        generation = task
        await task.value
    }
}
