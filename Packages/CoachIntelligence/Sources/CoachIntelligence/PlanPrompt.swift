import CoachCore
import Foundation

/// Turns a `WeekSummary` into the prompt text. Kept separate and pure so the
/// exact wording is covered by tests and reviewed like any other code.
enum PlanPrompt {
    static let instructions = """
    You are a friendly, practical fitness and habit coach inside an iPhone app. \
    Plan the user's next seven days starting tomorrow. Be specific and realistic, \
    progress load by no more than 10% week over week, and include at least one \
    recovery or mobility session. Never give medical advice.
    """

    static func text(for summary: WeekSummary, startingOn weekday: String) -> String {
        var lines = ["Last 7 days:"]
        lines.append("- Workouts: \(summary.workoutCount), total \(summary.workoutMinutes) minutes")
        if let steps = summary.averageDailySteps {
            lines.append("- Average steps per day: \(steps)")
        }
        if let energy = summary.averageActiveEnergy {
            lines.append("- Average active energy: \(energy) kcal")
        }
        if summary.habits.isEmpty {
            lines.append("- No habits tracked yet")
        } else {
            for habit in summary.habits {
                lines.append("- Habit \"\(habit.name)\": \(habit.completedDays)/7 days, streak \(habit.currentStreak)")
            }
        }
        lines.append("The plan starts on \(weekday).")
        return lines.joined(separator: "\n")
    }
}
