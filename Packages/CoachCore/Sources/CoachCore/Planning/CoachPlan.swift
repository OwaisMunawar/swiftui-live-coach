import Foundation

public struct CoachPlan: Hashable, Sendable, Codable {
    public enum Source: String, Hashable, Sendable, Codable {
        case onDeviceModel
        case ruleBased
    }

    public var headline: String
    public var summary: String
    public var sessions: [PlannedSession]
    public var source: Source
    public var generatedAt: Date

    public init(headline: String, summary: String, sessions: [PlannedSession], source: Source, generatedAt: Date = .now) {
        self.headline = headline
        self.summary = summary
        self.sessions = sessions
        self.source = source
        self.generatedAt = generatedAt
    }

    public var totalMinutes: Int { sessions.map(\.minutes).reduce(0, +) }
}

public struct PlannedSession: Hashable, Sendable, Codable, Identifiable {
    public var id: String { "\(weekday)-\(title)" }
    public var weekday: String
    public var kind: WorkoutKind
    public var title: String
    public var minutes: Int
    public var rationale: String

    public init(weekday: String, kind: WorkoutKind, title: String, minutes: Int, rationale: String) {
        self.weekday = weekday
        self.kind = kind
        self.title = title
        self.minutes = minutes
        self.rationale = rationale
    }
}

public protocol PlanGenerating: Sendable {
    func makePlan(for summary: WeekSummary) async throws -> CoachPlan
}
