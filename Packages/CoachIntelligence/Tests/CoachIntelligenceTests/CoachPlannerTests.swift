import CoachCore
import Foundation
import Testing
@testable import CoachIntelligence

private struct FixedAvailability: PlannerAvailabilityProviding {
    var availability: PlannerAvailability
}

private struct StubPlanner: PlanGenerating {
    enum Failure: Error { case boom }
    var source: CoachPlan.Source
    var fails = false

    func makePlan(for summary: WeekSummary) async throws -> CoachPlan {
        if fails { throw Failure.boom }
        return CoachPlan(headline: "Stub", summary: "", sessions: [], source: source,
                         generatedAt: Date(timeIntervalSince1970: 0))
    }
}

@Suite("Coach planner fallback")
struct CoachPlannerTests {
    let summary = WeekSummary(
        days: [],
        habits: [HabitWeekStat(name: "Read", completedDays: 3, currentStreak: 1)],
        workoutCount: 2,
        workoutMinutes: 70,
        averageDailySteps: 7_400
    )

    @Test func usesTheModelWhenAvailable() async throws {
        let planner = CoachPlanner(availability: FixedAvailability(availability: .available),
                                   modelPlanner: StubPlanner(source: .onDeviceModel),
                                   fallback: StubPlanner(source: .ruleBased))
        let outcome = try await planner.makePlan(for: summary)
        #expect(outcome.plan.source == .onDeviceModel)
        #expect(outcome.fallbackReason == nil)
    }

    @Test(arguments: [PlannerAvailability.Reason.deviceNotEligible, .appleIntelligenceNotEnabled, .modelNotReady])
    func fallsBackWhenTheModelIsUnavailable(reason: PlannerAvailability.Reason) async throws {
        let planner = CoachPlanner(availability: FixedAvailability(availability: .unavailable(reason)),
                                   modelPlanner: StubPlanner(source: .onDeviceModel),
                                   fallback: StubPlanner(source: .ruleBased))
        let outcome = try await planner.makePlan(for: summary)
        #expect(outcome.plan.source == .ruleBased)
        #expect(outcome.fallbackReason == reason.explanation)
    }

    @Test func fallsBackWhenGenerationFails() async throws {
        let planner = CoachPlanner(availability: FixedAvailability(availability: .available),
                                   modelPlanner: StubPlanner(source: .onDeviceModel, fails: true),
                                   fallback: RuleBasedPlanner())
        let outcome = try await planner.makePlan(for: summary)
        #expect(outcome.plan.source == .ruleBased)
        #expect(!outcome.plan.sessions.isEmpty)
        #expect(outcome.fallbackReason != nil)
    }

    @Test func mapsSystemAvailability() {
        #expect(PlannerAvailability(.available) == .available)
        #expect(PlannerAvailability(.unavailable(.modelNotReady)) == .unavailable(.modelNotReady))
    }

    @Test func promptCarriesTheWeeksNumbers() {
        let text = PlanPrompt.text(for: summary, startingOn: "Thursday")
        #expect(text.contains("Workouts: 2, total 70 minutes"))
        #expect(text.contains("Average steps per day: 7400"))
        #expect(text.contains("Habit \"Read\": 3/7 days, streak 1"))
        #expect(text.hasSuffix("The plan starts on Thursday."))
    }

    @Test func generatedPlanIsClampedIntoRenderableRanges() {
        let generated = GeneratedPlan(
            headline: "Go",
            summary: "",
            sessions: [GeneratedSession(weekday: "Monday", kind: "unknown", title: "Mystery", minutes: 500, rationale: "")]
        )
        let plan = generated.coachPlan(generatedAt: .now)
        #expect(plan.source == .onDeviceModel)
        #expect(plan.sessions.first?.kind == .strength)
        #expect(plan.sessions.first?.minutes == 75)
    }
}
