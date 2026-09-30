import AppIntents
import CoachCore
import Foundation

enum WorkoutKindOption: String, AppEnum {
    case run, strength, yoga, walk, focus

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Workout Type"
    // Literal symbol names: App Intents metadata is extracted at build time
    // and can't evaluate `WorkoutKind.symbolName`.
    static let caseDisplayRepresentations: [WorkoutKindOption: DisplayRepresentation] = [
        .run: DisplayRepresentation(title: "Run", image: .init(systemName: "figure.run")),
        .strength: DisplayRepresentation(title: "Strength", image: .init(systemName: "dumbbell.fill")),
        .yoga: DisplayRepresentation(title: "Yoga", image: .init(systemName: "figure.yoga")),
        .walk: DisplayRepresentation(title: "Walk", image: .init(systemName: "figure.walk")),
        .focus: DisplayRepresentation(title: "Focus", image: .init(systemName: "brain.head.profile")),
    ]

    var kind: WorkoutKind { WorkoutKind(rawValue: rawValue) ?? .strength }
}

/// "Start a workout in LiveCoach". A `LiveActivityIntent` so it may start the
/// Live Activity even when invoked from Siri with the app in the background.
struct StartWorkoutIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Start Workout"
    static let description = IntentDescription("Starts a timed session with a Live Activity.")

    @Parameter(title: "Type", default: .strength)
    var kind: WorkoutKindOption

    static var parameterSummary: some ParameterSummary {
        Summary("Start a \(\.$kind) session")
    }

    init() {}

    init(kind: WorkoutKindOption) {
        self.kind = kind
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let coordinator = WorkoutCoordinator(context: SharedModelContainer.shared.mainContext)
        let session = try coordinator.start(kind.kind)
        if session.kind != kind.kind {
            return .result(dialog: "You already have a \(session.kind.title.lowercased()) session running.")
        }
        return .result(dialog: "\(session.kind.title) started. Go get it.")
    }
}

struct TogglePauseWorkoutIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Pause or Resume Workout"
    static let isDiscoverable = false

    @Parameter(title: "Session ID")
    var sessionID: String

    init() {}

    init(sessionID: UUID) {
        self.sessionID = sessionID.uuidString
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let id = UUID(uuidString: sessionID) else { return .result() }
        try await WorkoutCoordinator(context: SharedModelContainer.shared.mainContext).togglePause(sessionID: id)
        return .result()
    }
}

struct CompleteWorkoutIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Complete Workout"
    static let isDiscoverable = false

    @Parameter(title: "Session ID")
    var sessionID: String

    init() {}

    init(sessionID: UUID) {
        self.sessionID = sessionID.uuidString
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let id = UUID(uuidString: sessionID) else { return .result() }
        try await WorkoutCoordinator(context: SharedModelContainer.shared.mainContext).complete(sessionID: id)
        return .result()
    }
}
