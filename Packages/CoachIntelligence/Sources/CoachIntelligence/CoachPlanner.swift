import CoachCore
import Foundation
import FoundationModels

/// Whether the on-device model can be used right now, with a reason the UI can
/// show when it cannot.
public enum PlannerAvailability: Equatable, Sendable {
    case available
    case unavailable(Reason)

    public enum Reason: Equatable, Sendable {
        case deviceNotEligible
        case appleIntelligenceNotEnabled
        case modelNotReady
        case other

        public var explanation: String {
            switch self {
            case .deviceNotEligible: "This device doesn't support Apple Intelligence."
            case .appleIntelligenceNotEnabled: "Turn on Apple Intelligence in Settings to get AI plans."
            case .modelNotReady: "The on-device model is still downloading."
            case .other: "Apple Intelligence is unavailable right now."
            }
        }
    }

    init(_ availability: SystemLanguageModel.Availability) {
        switch availability {
        case .available:
            self = .available
        case .unavailable(.deviceNotEligible):
            self = .unavailable(.deviceNotEligible)
        case .unavailable(.appleIntelligenceNotEnabled):
            self = .unavailable(.appleIntelligenceNotEnabled)
        case .unavailable(.modelNotReady):
            self = .unavailable(.modelNotReady)
        case .unavailable:
            self = .unavailable(.other)
        }
    }
}

public protocol PlannerAvailabilityProviding: Sendable {
    var availability: PlannerAvailability { get }
}

/// Reads `SystemLanguageModel.default.availability` each time, since the user
/// can toggle Apple Intelligence or the model can finish downloading while the
/// app is running.
public struct SystemModelAvailability: PlannerAvailabilityProviding {
    public init() {}

    public var availability: PlannerAvailability {
        PlannerAvailability(SystemLanguageModel.default.availability)
    }
}

public struct PlanOutcome: Sendable, Equatable {
    public var plan: CoachPlan
    /// Set when the fallback planner was used, explaining why.
    public var fallbackReason: String?

    public init(plan: CoachPlan, fallbackReason: String? = nil) {
        self.plan = plan
        self.fallbackReason = fallbackReason
    }
}

/// Chooses between the on-device model and the rule-based planner. The model is
/// preferred; any unavailability or generation error degrades to the
/// deterministic plan instead of an error screen.
public struct CoachPlanner: Sendable {
    private let availability: any PlannerAvailabilityProviding
    private let modelPlanner: any PlanGenerating
    private let fallback: any PlanGenerating

    public init(
        availability: any PlannerAvailabilityProviding,
        modelPlanner: any PlanGenerating,
        fallback: any PlanGenerating
    ) {
        self.availability = availability
        self.modelPlanner = modelPlanner
        self.fallback = fallback
    }

    public static func live(calendar: Calendar = .current) -> CoachPlanner {
        CoachPlanner(
            availability: SystemModelAvailability(),
            modelPlanner: FoundationModelPlanner(calendar: calendar),
            fallback: RuleBasedPlanner(calendar: calendar)
        )
    }

    public var currentAvailability: PlannerAvailability { availability.availability }

    public func makePlan(for summary: WeekSummary) async throws -> PlanOutcome {
        if case .unavailable(let reason) = availability.availability {
            return PlanOutcome(plan: try await fallback.makePlan(for: summary), fallbackReason: reason.explanation)
        }
        do {
            return PlanOutcome(plan: try await modelPlanner.makePlan(for: summary), fallbackReason: nil)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            let reason = Self.describe(error)
            return PlanOutcome(plan: try await fallback.makePlan(for: summary), fallbackReason: reason)
        }
    }

    static func describe(_ error: any Error) -> String {
        if let generationError = error as? LanguageModelSession.GenerationError {
            switch generationError {
            case .guardrailViolation, .refusal:
                return "The on-device model declined this request, so here's a standard plan."
            case .exceededContextWindowSize:
                return "Too much history for the on-device model, so here's a standard plan."
            default:
                break
            }
        }
        return "The on-device model couldn't finish, so here's a standard plan."
    }
}
