import CoachCore
import CoachUI
import SwiftData
import SwiftUI
import WidgetKit

struct HabitDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var matches: [Habit]
    @State private var isConfirmingDelete = false

    private let calendar = Calendar.current

    init(habitID: UUID) {
        _matches = Query(filter: #Predicate<Habit> { $0.id == habitID })
    }

    var body: some View {
        if let habit = matches.first {
            content(for: habit)
        } else {
            ContentUnavailableView("Habit not found", systemImage: "questionmark.circle")
        }
    }

    private func content(for habit: Habit) -> some View {
        let today = DayStamp(.now, calendar: calendar)
        let done = habit.completedDays
        let last30 = today.trailingWindow(30, calendar: calendar)
        let rate = StreakCalculator.completionRate(days: done, window: last30)
        let isDoneToday = habit.isCompleted(on: today)

        return ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 10) {
                    Image(systemName: habit.symbolName)
                        .font(.system(.largeTitle))
                        .foregroundStyle(habit.tint.color)
                        .frame(width: 80, height: 80)
                        .background(habit.tint.color.opacity(0.15), in: .circle)
                        .accessibilityHidden(true)
                    Text(habit.name)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) { tiles(habit: habit, today: today, rate: rate) }
                    VStack(spacing: 12) { tiles(habit: habit, today: today, rate: rate) }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Last 12 weeks")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                    HeatmapGrid(days: today.trailingWindow(84, calendar: calendar), completed: done, tint: habit.tint.color)
                }
                .coachCard()

                Button {
                    habit.toggle(on: today, in: context)
                    try? context.save()
                    WidgetCenter.shared.reloadTimelines(ofKind: WidgetKinds.todayHabits)
                } label: {
                    Label(isDoneToday ? "Done today" : "Mark done today",
                          systemImage: isDoneToday ? "checkmark.circle.fill" : "circle")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .tint(habit.tint.color)
                .controlSize(.large)
                .sensoryFeedback(.success, trigger: isDoneToday) { _, new in new }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu("More", systemImage: "ellipsis") {
                    Button("Delete Habit", systemImage: "trash", role: .destructive) { isConfirmingDelete = true }
                }
            }
        }
        .confirmationDialog("Delete \(habit.name)?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("Delete Habit", role: .destructive) {
                context.delete(habit)
                try? context.save()
                WidgetCenter.shared.reloadTimelines(ofKind: WidgetKinds.todayHabits)
                LiveCoachShortcuts.updateAppShortcutParameters()
                dismiss()
            }
        } message: {
            Text("This removes its entire history.")
        }
    }

    @ViewBuilder
    private func tiles(habit: Habit, today: DayStamp, rate: Double) -> some View {
        let current = habit.currentStreak(today: today, calendar: calendar)
        let best = habit.longestStreak(calendar: calendar)
        StatTile(title: "Streak", value: "\(current)", symbol: "flame.fill", tint: .orange,
                 spokenValue: "\(current) days")
        StatTile(title: "Best", value: "\(best)", symbol: "trophy.fill", tint: .yellow,
                 spokenValue: "\(best) days")
        StatTile(title: "30 days", value: rate.formatted(.percent.precision(.fractionLength(0))),
                 symbol: "chart.bar.fill", tint: habit.tint.color)
    }
}
