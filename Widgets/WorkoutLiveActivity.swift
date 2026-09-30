import ActivityKit
import CoachCore
import CoachUI
import SwiftUI
import WidgetKit

struct WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            LockScreenWorkoutView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.6))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            let kind = context.attributes.kind
            let clock = context.state.clock
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(kind.title, systemImage: kind.symbolName)
                        .font(.headline)
                        .foregroundStyle(kind.color)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ElapsedTimeText(clock: clock)
                        .font(.title2.weight(.semibold))
                        .frame(maxWidth: 110, alignment: .trailing)
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    WorkoutControls(sessionID: context.attributes.sessionID, isPaused: clock.isPaused)
                        .padding(.top, 6)
                }
            } compactLeading: {
                Image(systemName: clock.isPaused ? "pause.fill" : kind.symbolName)
                    .foregroundStyle(kind.color)
            } compactTrailing: {
                ElapsedTimeText(clock: clock)
                    .frame(maxWidth: 52)
                    .foregroundStyle(kind.color)
            } minimal: {
                Image(systemName: kind.symbolName)
                    .foregroundStyle(kind.color)
            }
            .keylineTint(kind.color)
        }
    }
}

private struct LockScreenWorkoutView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>

    var body: some View {
        let kind = context.attributes.kind
        let clock = context.state.clock
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Label(kind.title, systemImage: kind.symbolName)
                    .font(.headline)
                    .foregroundStyle(kind.color)
                Spacer()
                if clock.isPaused {
                    Text("Paused")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            ElapsedTimeText(clock: clock)
                .font(.system(size: 44, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            WorkoutControls(sessionID: context.attributes.sessionID, isPaused: clock.isPaused)
        }
        .padding()
    }
}

private struct WorkoutControls: View {
    let sessionID: UUID
    let isPaused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Button(intent: TogglePauseWorkoutIntent(sessionID: sessionID)) {
                Label(isPaused ? "Resume" : "Pause", systemImage: isPaused ? "play.fill" : "pause.fill")
                    .frame(maxWidth: .infinity)
            }
            .tint(.orange)

            Button(intent: CompleteWorkoutIntent(sessionID: sessionID)) {
                Label("Finish", systemImage: "checkmark")
                    .frame(maxWidth: .infinity)
            }
            .tint(.green)
        }
        .buttonStyle(.borderedProminent)
        .font(.subheadline.weight(.semibold))
    }
}

#Preview("Lock Screen", as: .content, using: WorkoutActivityAttributes(sessionID: UUID(), kind: .run)) {
    WorkoutLiveActivity()
} contentStates: {
    WorkoutActivityAttributes.ContentState(clock: SessionClock(startedAt: .now.addingTimeInterval(-754)))
    WorkoutActivityAttributes.ContentState(clock: SessionClock(startedAt: .now.addingTimeInterval(-900), pausedAt: .now))
}
