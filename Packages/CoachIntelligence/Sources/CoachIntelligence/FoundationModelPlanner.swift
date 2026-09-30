import CoachCore
import Foundation
import FoundationModels

/// Generates the weekly plan with Apple's on-device language model using
/// guided generation, so the response is a typed `GeneratedPlan` rather than
/// text that needs parsing.
public struct FoundationModelPlanner: PlanGenerating {
    private let calendar: Calendar
    private let now: @Sendable () -> Date

    public init(calendar: Calendar = .current, now: @escaping @Sendable () -> Date = { .now }) {
        self.calendar = calendar
        self.now = now
    }

    public func makePlan(for summary: WeekSummary) async throws -> CoachPlan {
        let date = now()
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        let weekday = tomorrow.formatted(Date.FormatStyle(timeZone: calendar.timeZone).weekday(.wide))

        let session = LanguageModelSession(instructions: PlanPrompt.instructions)
        let response = try await session.respond(
            to: PlanPrompt.text(for: summary, startingOn: weekday),
            generating: GeneratedPlan.self,
            options: GenerationOptions(temperature: 0.4)
        )
        return response.content.coachPlan(generatedAt: date)
    }
}
