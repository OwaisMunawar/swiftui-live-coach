import Foundation

public enum WorkoutKind: String, CaseIterable, Codable, Sendable, Identifiable {
    case run
    case strength
    case yoga
    case walk
    case focus

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .run: "Run"
        case .strength: "Strength"
        case .yoga: "Yoga"
        case .walk: "Walk"
        case .focus: "Focus"
        }
    }

    public var symbolName: String {
        switch self {
        case .run: "figure.run"
        case .strength: "dumbbell.fill"
        case .yoga: "figure.yoga"
        case .walk: "figure.walk"
        case .focus: "brain.head.profile"
        }
    }

    /// Focus blocks count as sessions but not as physical training.
    public var isPhysical: Bool { self != .focus }
}
