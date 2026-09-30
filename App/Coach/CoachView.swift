import CoachCore
import CoachIntelligence
import CoachUI
import SwiftData
import SwiftUI

struct CoachView: View {
    @Environment(CoachModel.self) private var coach
    @Environment(HealthModel.self) private var health
    @Query(sort: [SortDescriptor(\Habit.sortOrder)]) private var habits: [Habit]
    @Query(sort: [SortDescriptor(\WorkoutSession.startedAt, order: .reverse)]) private var sessions: [WorkoutSession]

    private var summary: WeekSummary {
        WeekSummary.make(habits: habits, sessions: sessions, activity: health.week)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                WeekStats(summary: summary)
                planSection
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Coach")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("New Plan", systemImage: "arrow.clockwise") {
                    Task { await coach.generate(for: summary) }
                }
                .disabled(coach.state == .generating)
            }
        }
        .task {
            await health.refresh()
            if coach.state == .idle {
                await coach.generate(for: summary)
            }
        }
    }

    @ViewBuilder
    private var planSection: some View {
        switch coach.state {
        case .idle, .generating:
            PlanCard(outcome: .placeholder)
                .redacted(reason: .placeholder)
                .overlay { ProgressView("Planning your week…").padding().background(.regularMaterial, in: .capsule) }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Planning your week")
        case .ready(let outcome):
            PlanCard(outcome: outcome)
        case .failed:
            ContentUnavailableView {
                Label("Couldn't build a plan", systemImage: "exclamationmark.triangle")
            } actions: {
                Button("Try Again") { Task { await coach.generate(for: summary) } }
            }
            .coachCard()
        }
    }
}

private struct WeekStats: View {
    let summary: WeekSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 7 days")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    StatTile(title: "Habits", value: summary.habitCompletionRate.formatted(.percent.precision(.fractionLength(0))),
                             symbol: "checklist", tint: .teal)
                    StatTile(title: "Workouts", value: "\(summary.workoutCount)", symbol: "figure.run", tint: .indigo)
                }
                GridRow {
                    StatTile(title: "Minutes", value: "\(summary.workoutMinutes)", symbol: "timer", tint: .orange)
                    StatTile(title: "Avg steps", value: summary.averageDailySteps.map { $0.formatted() } ?? "–",
                             symbol: "shoeprints.fill", tint: .green,
                             spokenValue: summary.averageDailySteps.map { $0.formatted() } ?? "No Health data")
                }
            }
        }
    }
}

private struct PlanCard: View {
    let outcome: PlanOutcome

    var body: some View {
        let plan = outcome.plan
        VStack(alignment: .leading, spacing: 14) {
            SourceBadge(source: plan.source)
            Text(plan.headline)
                .font(.title2.bold())
            Text(plan.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 0) {
                ForEach(plan.sessions) { session in
                    SessionRow(session: session)
                    if session.id != plan.sessions.last?.id {
                        Divider().padding(.leading, 48)
                    }
                }
            }

            HStack {
                Text("\(plan.sessions.count) sessions")
                Spacer()
                Text("\(plan.totalMinutes) min total")
            }
            .font(.footnote.weight(.medium))
            .foregroundStyle(.secondary)

            if let reason = outcome.fallbackReason {
                Label(reason, systemImage: "info.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .coachCard()
    }
}

private struct SourceBadge: View {
    let source: CoachPlan.Source

    var body: some View {
        Label(title, systemImage: symbol)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundStyle(tint)
            .background(tint.opacity(0.15), in: .capsule)
    }

    private var title: String {
        switch source {
        case .onDeviceModel: "Apple Intelligence · on-device"
        case .ruleBased: "Rule-based planner"
        }
    }

    private var symbol: String {
        switch source {
        case .onDeviceModel: "apple.intelligence"
        case .ruleBased: "list.bullet.clipboard"
        }
    }

    private var tint: Color {
        source == .onDeviceModel ? .purple : .teal
    }
}

private struct SessionRow: View {
    let session: PlannedSession

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: session.kind.symbolName)
                .font(.title3)
                .foregroundStyle(session.kind.color)
                .frame(width: 36, height: 36)
                .background(session.kind.color.opacity(0.15), in: .circle)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline) {
                    Text(session.weekday)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text("\(session.minutes) min")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Text(session.title)
                    .font(.body)
                Text(session.rationale)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
    }
}

extension PlanOutcome {
    static let placeholder = PlanOutcome(
        plan: CoachPlan(
            headline: "Planning your week",
            summary: "Looking at your habits, workouts and activity.",
            sessions: (0..<3).map {
                PlannedSession(weekday: "Weekday", kind: .strength, title: "Session \($0)", minutes: 30,
                               rationale: "Placeholder rationale text")
            },
            source: .ruleBased
        ),
        fallbackReason: nil
    )
}
