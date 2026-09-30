import CoachCore
import Foundation
import FoundationModels

/// Schema the on-device model fills in. Guides keep the output inside ranges
/// the UI can render, so no post-hoc parsing or validation of free text.
@Generable(description: "A short, encouraging training plan for the coming week")
struct GeneratedPlan: Sendable {
    @Guide(description: "A punchy headline of at most six words")
    var headline: String

    @Guide(description: "One or two sentences that reference the user's actual numbers")
    var summary: String

    @Guide(description: "Planned sessions in chronological order", .count(3...5))
    var sessions: [GeneratedSession]
}

@Generable
struct GeneratedSession: Sendable {
    @Guide(.anyOf(["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]))
    var weekday: String

    @Guide(.anyOf(WorkoutKind.allCases.map(\.rawValue)))
    var kind: String

    @Guide(description: "Two to four words, e.g. 'Easy run'")
    var title: String

    @Guide(.range(10...75))
    var minutes: Int

    @Guide(description: "Why this session, in one short sentence")
    var rationale: String
}

extension GeneratedPlan {
    func coachPlan(generatedAt: Date) -> CoachPlan {
        CoachPlan(
            headline: headline,
            summary: summary,
            sessions: sessions.map {
                PlannedSession(
                    weekday: $0.weekday,
                    kind: WorkoutKind(rawValue: $0.kind) ?? .strength,
                    title: $0.title,
                    minutes: min(75, max(10, $0.minutes)),
                    rationale: $0.rationale
                )
            },
            source: .onDeviceModel,
            generatedAt: generatedAt
        )
    }
}
