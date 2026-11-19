import CoachCore
import CoachUI
import SwiftData
import SwiftUI
import WidgetKit

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Environment(HealthModel.self) private var health
    @Query(sort: [SortDescriptor(\Habit.sortOrder), SortDescriptor(\Habit.createdAt)]) private var habits: [Habit]
    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt == nil }) private var activeSessions: [WorkoutSession]
    @State private var isAddingHabit = false

    private var today: DayStamp { DayStamp(.now) }
    private var doneCount: Int { habits.filter { $0.isCompleted(on: today) }.count }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ProgressHeader(done: doneCount, total: habits.count)

                if let session = activeSessions.first {
                    ActiveWorkoutCard(session: session)
                } else {
                    StartWorkoutMenu()
                }

                habitsSection
                HealthCard()
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Today")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add Habit", systemImage: "plus") { isAddingHabit = true }
            }
        }
        .sheet(isPresented: $isAddingHabit) {
            AddHabitView(nextSortOrder: (habits.map(\.sortOrder).max() ?? -1) + 1)
        }
        .task { await health.refresh() }
    }

    @ViewBuilder
    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Habits")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
                .padding(.bottom, 4)

            if habits.isEmpty {
                ContentUnavailableView {
                    Label("No habits yet", systemImage: "checklist")
                } description: {
                    Text("Add a habit to start building a streak.")
                } actions: {
                    Button("Add Habit") { isAddingHabit = true }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                ForEach(habits) { habit in
                    HabitRow(habit: habit, today: today, toggle: { toggle(habit) })
                    if habit.id != habits.last?.id {
                        Divider().padding(.leading, 44)
                    }
                }
            }
        }
        .coachCard()
    }

    private func toggle(_ habit: Habit) {
        habit.toggle(on: today, in: context)
        try? context.save()
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKinds.todayHabits)
    }
}

private struct ProgressHeader: View {
    let done: Int
    let total: Int

    var body: some View {
        HStack(spacing: 20) {
            ProgressRing(progress: total == 0 ? 0 : Double(done) / Double(total), lineWidth: 12, tint: .teal)
                .frame(width: 84, height: 84)
                .overlay {
                    Text("\(done)/\(total)")
                        .font(.headline.monospacedDigit())
                }
            VStack(alignment: .leading, spacing: 4) {
                Text(Date.now, format: .dateTime.weekday(.wide).day().month(.wide))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(message)
                    .font(.title3.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .coachCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(done) of \(total) habits done today. \(message)")
    }

    private var message: String {
        switch (done, total) {
        case (_, 0): "Let's set up your first habit."
        case let (done, total) where done == total: "All done. Nice work."
        case (0, _): "Fresh day. Pick one to start."
        default: "\(total - done) to go today."
        }
    }
}

struct HabitRow: View {
    let habit: Habit
    let today: DayStamp
    let toggle: () -> Void

    private let calendar = Calendar.current

    var body: some View {
        let isDone = habit.isCompleted(on: today)
        let weekly = habit.weeklyProgress(today: today, calendar: calendar)
        let streak = streakBadge(weekly: weekly)
        HStack(spacing: 12) {
            Button(action: toggle) {
                HabitCheckmark(isDone: isDone, tint: habit.tint.color)
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.success, trigger: isDone) { _, new in new }
            .accessibilityLabel(habit.name)
            .accessibilityValue(isDone ? "Done" : "Not done")
            .accessibilityHint("Double tap to toggle today's completion")

            NavigationLink(value: habit.id) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Label {
                            Text(habit.name)
                                .foregroundStyle(.primary)
                        } icon: {
                            Image(systemName: habit.symbolName)
                                .foregroundStyle(habit.tint.color)
                                .frame(minWidth: 28)
                        }
                        if let weekly {
                            WeeklyGoalCaption(progress: weekly)
                                .padding(.leading, 40)
                        }
                    }
                    Spacer()
                    if let streak {
                        Label("\(streak.count)", systemImage: "flame.fill")
                            .font(.subheadline.monospacedDigit().weight(.medium))
                            .foregroundStyle(.orange)
                            .accessibilityLabel(streak.spoken)
                    }
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Shows streaks and history")
        }
        .padding(.vertical, 6)
    }

    /// Weekly habits show their run of met weeks; daily habits their run of days.
    private func streakBadge(weekly: WeeklyProgress?) -> (count: Int, spoken: String)? {
        if weekly != nil, let weeks = habit.weeklyStreak(today: today, calendar: calendar) {
            return weeks > 0 ? (weeks, "\(weeks) week streak") : nil
        }
        let days = habit.currentStreak(today: today, calendar: calendar)
        return days > 0 ? (days, "\(days) day streak") : nil
    }
}

private struct WeeklyGoalCaption: View {
    let progress: WeeklyProgress

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(progress.isMet ? Color.green : progress.isReachable ? Color.secondary : Color.red)
    }

    private var text: String {
        if progress.isMet { return "Goal met this week" }
        if !progress.isReachable { return "\(progress.completed) of \(progress.target) this week, out of reach" }
        return "\(progress.completed) of \(progress.target) this week"
    }
}

#Preview {
    NavigationStack { TodayView() }
        .environment(HealthModel(provider: AppDependencies.preview.activity))
        .modelContainer(PreviewData.container)
}
