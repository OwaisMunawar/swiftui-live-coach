import ActivityKit
import CoachCore
import Foundation
import OSLog
import SwiftData

/// Starts, pauses and completes workout sessions and keeps the matching Live
/// Activity in sync. Used by the app UI and by the App Intents behind Siri,
/// Shortcuts and the Live Activity buttons, so all paths behave identically.
@MainActor
struct WorkoutCoordinator {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    /// Starts a session, or returns the one already running. Only one session
    /// can be active at a time.
    @discardableResult
    func start(_ kind: WorkoutKind, at now: Date = .now) throws -> WorkoutSession {
        if let active = try context.activeWorkoutSession() {
            return active
        }
        let session = WorkoutSession(kind: kind, startedAt: now)
        context.insert(session)
        try context.save()
        requestActivity(for: session)
        return session
    }

    func togglePause(sessionID: UUID, at now: Date = .now) async throws {
        guard let session = try context.workoutSession(id: sessionID), session.isActive else { return }
        session.togglePause(at: now)
        try context.save()
        let state = WorkoutActivityAttributes.ContentState(clock: session.clock)
        await Self.activity(for: sessionID)?.update(ActivityContent(state: state, staleDate: nil))
    }

    func complete(sessionID: UUID, at now: Date = .now) async throws {
        guard let session = try context.workoutSession(id: sessionID) else { return }
        session.complete(at: now)
        try context.save()
        let state = WorkoutActivityAttributes.ContentState(clock: session.clock)
        await Self.activity(for: sessionID)?.end(ActivityContent(state: state, staleDate: nil), dismissalPolicy: .default)
    }

    /// Ends Live Activities whose session finished while the app wasn't
    /// running, e.g. after a crash or a store reset.
    func reconcileActivities() async {
        for activity in Activity<WorkoutActivityAttributes>.activities {
            let session = try? context.workoutSession(id: activity.attributes.sessionID)
            if session?.isActive != true {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    private func requestActivity(for session: WorkoutSession) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            Logger.workouts.info("Live Activities are disabled; session runs without one")
            return
        }
        do {
            _ = try Activity.request(
                attributes: WorkoutActivityAttributes(sessionID: session.id, kind: session.kind),
                content: ActivityContent(state: .init(clock: session.clock), staleDate: nil)
            )
        } catch {
            Logger.workouts.error("Live Activity request failed: \(error.localizedDescription)")
        }
    }

    /// Nonisolated so the returned activity is in a disconnected region and can
    /// be handed to ActivityKit's async update/end without crossing actors.
    private nonisolated static func activity(for sessionID: UUID) -> Activity<WorkoutActivityAttributes>? {
        Activity<WorkoutActivityAttributes>.activities.first { $0.attributes.sessionID == sessionID }
    }
}
