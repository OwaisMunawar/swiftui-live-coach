import CoachCore
import CoachUI
import SwiftData
import SwiftUI

struct ActiveWorkoutCard: View {
    @Environment(\.modelContext) private var context
    let session: WorkoutSession

    var body: some View {
        let kind = session.kind
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(kind.title, systemImage: kind.symbolName)
                    .font(.headline)
                    .foregroundStyle(kind.color)
                Spacer()
                Text(session.clock.isPaused ? "Paused" : "In progress")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            ElapsedTimeText(clock: session.clock)
                .font(.system(.largeTitle, design: .rounded, weight: .semibold))
                .accessibilityLabel("Elapsed time")

            HStack(spacing: 12) {
                Button {
                    Task { try? await coordinator.togglePause(sessionID: session.id) }
                } label: {
                    Label(session.clock.isPaused ? "Resume" : "Pause",
                          systemImage: session.clock.isPaused ? "play.fill" : "pause.fill")
                        .frame(maxWidth: .infinity)
                }
                .tint(.orange)

                Button {
                    Task { try? await coordinator.complete(sessionID: session.id) }
                } label: {
                    Label("Finish", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .tint(.green)
            }
            .buttonStyle(.glassProminent)
            .foregroundStyle(.white)
            .controlSize(.large)
        }
        .coachCard()
    }

    private var coordinator: WorkoutCoordinator {
        WorkoutCoordinator(context: context)
    }
}

struct StartWorkoutMenu: View {
    @Environment(\.modelContext) private var context

    var body: some View {
        Menu {
            ForEach(WorkoutKind.allCases) { kind in
                Button(kind.title, systemImage: kind.symbolName) {
                    _ = try? WorkoutCoordinator(context: context).start(kind)
                }
            }
        } label: {
            Label("Start a session", systemImage: "play.circle.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.glassProminent)
        .foregroundStyle(.white)
        .controlSize(.large)
        .accessibilityHint("Choose a workout type. A Live Activity keeps the timer on your Lock Screen.")
    }
}
