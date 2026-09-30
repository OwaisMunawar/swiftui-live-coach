import AppIntents
import CoachCore
import Foundation
import WidgetKit

/// Backs the check buttons in the interactive widget. Toggling (rather than
/// only completing) lets people undo an accidental tap from the Home Screen.
struct ToggleHabitIntent: AppIntent {
    static let title: LocalizedStringResource = "Toggle Habit"
    static let isDiscoverable = false

    @Parameter(title: "Habit ID")
    var habitID: String

    init() {}

    init(habitID: UUID) {
        self.habitID = habitID.uuidString
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let context = SharedModelContainer.shared.mainContext
        guard let id = UUID(uuidString: habitID), let habit = try context.habit(id: id) else {
            return .result()
        }
        habit.toggle(on: DayStamp(.now), in: context)
        try context.save()
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKinds.todayHabits)
        return .result()
    }
}

/// "Log water in LiveCoach". Always marks done, so repeating it is harmless.
struct LogHabitIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Habit"
    static let description = IntentDescription("Marks a habit as done for today.")

    @Parameter(title: "Habit", requestValueDialog: "Which habit did you finish?")
    var habit: HabitEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$habit) for today")
    }

    init() {}

    init(habit: HabitEntity) {
        self.habit = habit
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = SharedModelContainer.shared.mainContext
        guard let model = try context.habit(id: habit.id) else {
            return .result(dialog: "I couldn't find that habit.")
        }
        let today = DayStamp(.now)
        model.markCompleted(on: today, in: context)
        try context.save()
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKinds.todayHabits)

        let streak = model.currentStreak(today: today, calendar: .current)
        let suffix = streak > 1 ? " That's \(streak) days in a row." : ""
        return .result(dialog: "Logged \(model.name).\(suffix)")
    }
}
