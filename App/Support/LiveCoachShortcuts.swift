import AppIntents

struct LiveCoachShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartWorkoutIntent(),
            phrases: [
                "Start a workout in \(.applicationName)",
                "Start a \(\.$kind) workout in \(.applicationName)",
                "Start a \(\.$kind) session with \(.applicationName)",
            ],
            shortTitle: "Start Workout",
            systemImageName: "figure.run"
        )
        AppShortcut(
            intent: LogHabitIntent(),
            phrases: [
                "Log a habit in \(.applicationName)",
                "Log \(\.$habit) in \(.applicationName)",
                "Mark \(\.$habit) done in \(.applicationName)",
            ],
            shortTitle: "Log Habit",
            systemImageName: "checkmark.circle"
        )
    }

    static let shortcutTileColor: ShortcutTileColor = .teal
}
