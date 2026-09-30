import Foundation
import SwiftData

/// Deterministic sample data for screenshots, previews and the `-demoData`
/// launch argument.
public enum DemoSeed {
    struct Template {
        let name: String
        let symbol: String
        let tint: HabitTint
        /// Probability of completing on any given day, before the streak tail.
        let adherence: Double
        /// Guaranteed completed days leading up to today.
        let streak: Int
    }

    static let templates: [Template] = [
        Template(name: "Morning stretch", symbol: "figure.flexibility", tint: .teal, adherence: 0.8, streak: 12),
        Template(name: "Drink 2L water", symbol: "drop.fill", tint: .indigo, adherence: 0.9, streak: 21),
        Template(name: "Read 20 pages", symbol: "book.fill", tint: .orange, adherence: 0.6, streak: 4),
        Template(name: "No screens after 10pm", symbol: "moon.zzz.fill", tint: .pink, adherence: 0.35, streak: 0),
        Template(name: "Meditate", symbol: "brain.head.profile", tint: .green, adherence: 0.7, streak: 6),
    ]

    struct PastWorkout {
        let daysAgo: Int
        let kind: WorkoutKind
        let minutes: Double
    }

    static let pastWorkouts: [PastWorkout] = [
        PastWorkout(daysAgo: 1, kind: .strength, minutes: 42),
        PastWorkout(daysAgo: 2, kind: .run, minutes: 28),
        PastWorkout(daysAgo: 4, kind: .strength, minutes: 38),
        PastWorkout(daysAgo: 6, kind: .yoga, minutes: 20),
        PastWorkout(daysAgo: 8, kind: .run, minutes: 31),
        PastWorkout(daysAgo: 10, kind: .strength, minutes: 35),
        PastWorkout(daysAgo: 13, kind: .walk, minutes: 45),
    ]

    @MainActor
    public static func populate(_ context: ModelContext, now: Date = .now, calendar: Calendar = .current) throws {
        // Row-by-row rather than `delete(model:)`: batch deletes trip over the
        // habit/completion inverse relationship in the underlying store.
        try context.fetch(FetchDescriptor<Habit>()).forEach(context.delete)
        try context.fetch(FetchDescriptor<HabitCompletion>()).forEach(context.delete)
        try context.fetch(FetchDescriptor<WorkoutSession>()).forEach(context.delete)
        try context.save()

        var random = SeededGenerator(seed: 2011)
        let today = DayStamp(now, calendar: calendar)

        for (index, template) in templates.enumerated() {
            let created = today.adding(days: -84, calendar: calendar).noon(in: calendar)
            let habit = Habit(name: template.name, symbolName: template.symbol, tint: template.tint,
                              createdAt: created, sortOrder: index)
            context.insert(habit)

            // Leave "today" open for most habits so the check buttons have
            // something to do in a fresh demo.
            let todayDone = index < 2
            for offset in 0..<84 {
                let day = today.adding(days: -offset, calendar: calendar)
                let done: Bool
                if offset == 0 {
                    done = todayDone
                } else if offset <= template.streak {
                    done = true
                } else if offset == template.streak + 1 {
                    done = false
                } else {
                    done = Double.random(in: 0..<1, using: &random) < template.adherence
                }
                if done {
                    habit.markCompleted(on: day, in: context, at: day.noon(in: calendar))
                }
            }
        }

        for workout in pastWorkouts {
            let start = today.adding(days: -workout.daysAgo, calendar: calendar).noon(in: calendar)
                .addingTimeInterval(-4 * 3600)
            let session = WorkoutSession(kind: workout.kind, startedAt: start)
            session.complete(at: start.addingTimeInterval(workout.minutes * 60))
            context.insert(session)
        }

        try context.save()
    }
}

/// SplitMix64, so demo data is identical on every run and every machine.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
