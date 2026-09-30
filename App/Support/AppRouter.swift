import CoachCore
import Foundation
import Observation
import SwiftData

enum AppTab: Hashable {
    case today, coach, workouts
}

/// Tab and navigation state, plus the `livecoach://` URL scheme:
///
///     livecoach://today
///     livecoach://coach
///     livecoach://workouts
///     livecoach://habit/<uuid or exact name>
///     livecoach://workout/start/<run|strength|yoga|walk|focus>
@MainActor
@Observable
final class AppRouter {
    var tab: AppTab = .today
    var todayPath: [UUID] = []

    func handle(_ url: URL, context: ModelContext) {
        guard url.scheme == "livecoach" else { return }
        let parts = url.pathComponents.filter { $0 != "/" }

        switch url.host() {
        case "today":
            tab = .today
            todayPath = []
        case "coach":
            tab = .coach
        case "workouts":
            tab = .workouts
        case "habit":
            guard let key = parts.first, let habit = resolveHabit(key, in: context) else { return }
            tab = .today
            todayPath = [habit.id]
        case "workout":
            guard parts.first == "start", let raw = parts.dropFirst().first, let kind = WorkoutKind(rawValue: raw) else { return }
            _ = try? WorkoutCoordinator(context: context).start(kind)
            tab = .today
        default:
            break
        }
    }

    private func resolveHabit(_ key: String, in context: ModelContext) -> Habit? {
        if let id = UUID(uuidString: key) {
            return try? context.habit(id: id)
        }
        let name = key.removingPercentEncoding ?? key
        return try? context.habits().first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }
}
