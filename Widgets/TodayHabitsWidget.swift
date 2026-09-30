import CoachCore
import CoachUI
import SwiftData
import SwiftUI
import WidgetKit

struct HabitSnapshot: Identifiable, Hashable {
    let id: UUID
    let name: String
    let symbolName: String
    let tint: HabitTint
    let isDone: Bool
    let streak: Int
}

struct TodayEntry: TimelineEntry {
    let date: Date
    let habits: [HabitSnapshot]

    var doneCount: Int { habits.filter(\.isDone).count }
    var progress: Double { habits.isEmpty ? 0 : Double(doneCount) / Double(habits.count) }

    static let placeholder = TodayEntry(date: .now, habits: [
        HabitSnapshot(id: UUID(), name: "Morning stretch", symbolName: "figure.flexibility", tint: .teal, isDone: true, streak: 12),
        HabitSnapshot(id: UUID(), name: "Drink 2L water", symbolName: "drop.fill", tint: .indigo, isDone: true, streak: 21),
        HabitSnapshot(id: UUID(), name: "Read 20 pages", symbolName: "book.fill", tint: .orange, isDone: false, streak: 4),
        HabitSnapshot(id: UUID(), name: "Meditate", symbolName: "brain.head.profile", tint: .green, isDone: false, streak: 6),
    ])
}

struct TodayProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
        completion(context.isPreview ? .placeholder : currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
        let entry = currentEntry()
        // Interactive taps reload explicitly; the only scheduled refresh is
        // midnight, when every check resets.
        let midnight = Calendar.current.nextDate(after: entry.date, matching: DateComponents(hour: 0), matchingPolicy: .nextTime)
        completion(Timeline(entries: [entry], policy: midnight.map { .after($0) } ?? .atEnd))
    }

    /// Uses a private context, so this is safe off the main actor.
    private func currentEntry(now: Date = .now) -> TodayEntry {
        let context = ModelContext(SharedModelContainer.shared)
        let today = DayStamp(now)
        let habits = (try? context.habits()) ?? []
        return TodayEntry(date: now, habits: habits.map { habit in
            HabitSnapshot(
                id: habit.id,
                name: habit.name,
                symbolName: habit.symbolName,
                tint: habit.tint,
                isDone: habit.isCompleted(on: today),
                streak: habit.currentStreak(today: today, calendar: .current)
            )
        })
    }
}

struct TodayHabitsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetKinds.todayHabits, provider: TodayProvider()) { entry in
            TodayHabitsView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today's Habits")
        .description("Check off habits without opening the app.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct TodayHabitsView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TodayEntry

    private var visibleHabits: [HabitSnapshot] {
        let limit = switch family {
        case .systemSmall: 3
        case .systemMedium: 4
        default: 8
        }
        return Array(entry.habits.prefix(limit))
    }

    var body: some View {
        if entry.habits.isEmpty {
            ContentUnavailableView("No habits yet", systemImage: "checklist", description: Text("Add one in LiveCoach."))
        } else if family == .systemSmall {
            smallLayout
        } else {
            listLayout
        }
    }

    private var header: some View {
        HStack {
            Text("Today")
                .font(.headline)
            Spacer()
            Text("\(entry.doneCount)/\(entry.habits.count)")
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            ForEach(visibleHabits) { habit in
                HStack(spacing: 8) {
                    checkButton(for: habit)
                    Image(systemName: habit.symbolName)
                        .foregroundStyle(habit.tint.color)
                        .accessibilityHidden(true)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var listLayout: some View {
        VStack(alignment: .leading, spacing: 6) {
            header
            ForEach(visibleHabits) { habit in
                HStack(spacing: 10) {
                    checkButton(for: habit)
                    Label(habit.name, systemImage: habit.symbolName)
                        .labelStyle(TintedIconLabelStyle(tint: habit.tint.color))
                        .font(.subheadline)
                        .lineLimit(1)
                        .strikethrough(habit.isDone, color: .secondary)
                    Spacer()
                    if habit.streak > 1 {
                        Label("\(habit.streak)", systemImage: "flame.fill")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.orange)
                            .accessibilityLabel("\(habit.streak) day streak")
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }

    private func checkButton(for habit: HabitSnapshot) -> some View {
        Button(intent: ToggleHabitIntent(habitID: habit.id)) {
            HabitCheckmark(isDone: habit.isDone, tint: habit.tint.color)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(habit.name)
        .accessibilityValue(habit.isDone ? "Done" : "Not done")
        .accessibilityHint("Toggles today's completion")
    }
}

private struct TintedIconLabelStyle: LabelStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.icon.foregroundStyle(tint)
            configuration.title
        }
    }
}

#Preview(as: .systemMedium) {
    TodayHabitsWidget()
} timeline: {
    TodayEntry.placeholder
}
