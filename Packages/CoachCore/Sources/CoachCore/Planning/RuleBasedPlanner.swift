import Foundation

/// Deterministic planner used when Apple Intelligence is unavailable
/// (older devices, Intelligence turned off, model still downloading) and as
/// the safety net when the on-device model fails.
public struct RuleBasedPlanner: PlanGenerating {
    public static let maxSessions = 5
    public static let lowStepThreshold = 6_000

    private let calendar: Calendar
    private let now: @Sendable () -> Date

    public init(calendar: Calendar = .current, now: @escaping @Sendable () -> Date = { .now }) {
        self.calendar = calendar
        self.now = now
    }

    public func makePlan(for summary: WeekSummary) async throws -> CoachPlan {
        plan(for: summary)
    }

    public func plan(for summary: WeekSummary) -> CoachPlan {
        let upcoming = upcomingWeekdays()
        var sessions: [PlannedSession] = []

        let headline: String
        let base: Int
        switch summary.workoutCount {
        case 0:
            headline = "Start small, start this week"
            base = 20
            sessions += [
                PlannedSession(weekday: upcoming[0], kind: .walk, title: "Brisk walk", minutes: base,
                               rationale: "No sessions logged last week. An easy win rebuilds the habit."),
                PlannedSession(weekday: upcoming[2], kind: .strength, title: "Full-body basics", minutes: base,
                               rationale: "Two short strength sessions a week is the evidence-backed minimum."),
                PlannedSession(weekday: upcoming[4], kind: .yoga, title: "Mobility flow", minutes: 15,
                               rationale: "Keeps the week varied and recovery-friendly."),
            ]
        case 1...2:
            headline = "Build on last week"
            base = 30
            sessions += [
                PlannedSession(weekday: upcoming[0], kind: .strength, title: "Strength", minutes: base,
                               rationale: "You trained \(summary.workoutCount)x last week. Adding one more session is sustainable."),
                PlannedSession(weekday: upcoming[2], kind: .run, title: "Easy run", minutes: 25,
                               rationale: "Conversational pace builds your aerobic base."),
                PlannedSession(weekday: upcoming[4], kind: .strength, title: "Strength", minutes: base,
                               rationale: "Repeat the first session with slightly more load."),
            ]
        default:
            headline = "Keep the momentum"
            let average = summary.workoutMinutes / max(summary.workoutCount, 1)
            // Progressive overload: roughly +10% on the average session length.
            base = min(75, max(25, Int((Double(average) * 1.1).rounded())))
            sessions += [
                PlannedSession(weekday: upcoming[0], kind: .strength, title: "Strength", minutes: base,
                               rationale: "\(summary.workoutCount) sessions last week. Nudging duration up about 10%."),
                PlannedSession(weekday: upcoming[1], kind: .run, title: "Tempo run", minutes: max(20, base - 10),
                               rationale: "One harder cardio day per week."),
                PlannedSession(weekday: upcoming[3], kind: .strength, title: "Strength", minutes: base,
                               rationale: "Second strength day, 48 hours after the first."),
                PlannedSession(weekday: upcoming[5], kind: .yoga, title: "Recovery yoga", minutes: 20,
                               rationale: "Deliberate recovery keeps a high-volume week injury-free."),
            ]
        }

        if let steps = summary.averageDailySteps, steps < Self.lowStepThreshold {
            sessions.append(PlannedSession(
                weekday: upcoming[6], kind: .walk, title: "Long walk", minutes: 40,
                rationale: "Average of \(steps.formatted()) steps a day. A long walk lifts the baseline."
            ))
        }

        if let weakest = summary.weakestHabit, weakest.completedDays < 4 {
            sessions.append(PlannedSession(
                weekday: upcoming[1], kind: .focus, title: "Protect \(weakest.name.lowercased())", minutes: 10,
                rationale: "Done on \(weakest.completedDays) of 7 days. Schedule it like a meeting."
            ))
        }

        return CoachPlan(
            headline: headline,
            summary: summaryLine(for: summary),
            sessions: Array(sessions.prefix(Self.maxSessions)),
            source: .ruleBased,
            generatedAt: now()
        )
    }

    private func summaryLine(for summary: WeekSummary) -> String {
        var parts: [String] = []
        let rate = Int((summary.habitCompletionRate * 100).rounded())
        if !summary.habits.isEmpty {
            parts.append("Habits hit \(rate)% of the time")
        }
        parts.append("\(summary.workoutCount) workout\(summary.workoutCount == 1 ? "" : "s") for \(summary.workoutMinutes) min")
        if let best = summary.strongestStreak, best.currentStreak >= 3 {
            parts.append("\(best.name) is on a \(best.currentStreak)-day streak")
        }
        return parts.joined(separator: " · ") + "."
    }

    /// Weekday names for the next seven days, starting tomorrow.
    private func upcomingWeekdays() -> [String] {
        let today = DayStamp(now(), calendar: calendar)
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEEE"
        return (1...7).map { formatter.string(from: today.adding(days: $0, calendar: calendar).noon(in: calendar)) }
    }
}
