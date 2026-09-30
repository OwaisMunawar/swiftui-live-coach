import CoachCore
import OSLog
import SwiftData

/// Composition root for persistence, compiled into both the app and the widget
/// extension. Domain code never reaches for this; it receives a `ModelContext`.
enum SharedModelContainer {
    static let shared: ModelContainer = {
        do {
            return try CoachStore.makeContainer()
        } catch {
            // A store that can't be opened shouldn't brick the app or widget.
            Logger.persistence.error("Falling back to an in-memory store: \(error.localizedDescription)")
            do {
                return try CoachStore.makeContainer(inMemory: true)
            } catch {
                fatalError("Unable to create even an in-memory ModelContainer: \(error)")
            }
        }
    }()
}

enum WidgetKinds {
    static let todayHabits = "TodayHabits"
}

extension Logger {
    private static let subsystem = "com.owaismunawar.livecoach"
    static let persistence = Logger(subsystem: subsystem, category: "persistence")
    static let workouts = Logger(subsystem: subsystem, category: "workouts")
    static let health = Logger(subsystem: subsystem, category: "health")
}
