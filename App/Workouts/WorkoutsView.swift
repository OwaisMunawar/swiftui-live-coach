import CoachCore
import CoachUI
import SwiftData
import SwiftUI

struct WorkoutsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\WorkoutSession.startedAt, order: .reverse)]) private var sessions: [WorkoutSession]

    private var active: WorkoutSession? { sessions.first(where: \.isActive) }
    private var history: [WorkoutSession] { sessions.filter { !$0.isActive } }

    var body: some View {
        List {
            Section {
                if let active {
                    ActiveWorkoutCard(session: active)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 12)], spacing: 12) {
                        ForEach(WorkoutKind.allCases) { kind in
                            Button {
                                _ = try? WorkoutCoordinator(context: context).start(kind)
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: kind.symbolName)
                                        .font(.title2)
                                    Text(kind.title)
                                        .font(.subheadline.weight(.semibold))
                                }
                                .frame(maxWidth: .infinity, minHeight: 72)
                            }
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.roundedRectangle(radius: 16))
                            .tint(kind.color)
                            .accessibilityLabel("Start \(kind.title)")
                        }
                    }
                    .padding(.vertical, 6)
                }
            } header: {
                Text(active == nil ? "Start" : "In progress")
            }

            Section("History") {
                if history.isEmpty {
                    Text("Finished sessions will appear here.")
                        .foregroundStyle(.secondary)
                }
                ForEach(history) { session in
                    HistoryRow(session: session)
                }
                .onDelete { offsets in
                    offsets.map { history[$0] }.forEach(context.delete)
                    try? context.save()
                }
            }
        }
        .navigationTitle("Workouts")
    }
}

private struct HistoryRow: View {
    let session: WorkoutSession

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: session.kind.symbolName)
                .foregroundStyle(session.kind.color)
                .frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(session.kind.title)
                    .font(.body.weight(.medium))
                Text(session.startedAt, format: .dateTime.weekday(.wide).day().month().hour().minute())
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(Duration.seconds(session.activeDuration()), format: .units(allowed: [.hours, .minutes], width: .abbreviated))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}
