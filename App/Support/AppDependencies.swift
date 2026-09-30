import CoachCore
import CoachHealth
import CoachIntelligence
import Foundation

/// Everything with side effects that the feature models depend on. The app
/// builds `live` once at launch; previews swap in deterministic fakes.
struct AppDependencies {
    var planner: CoachPlanner
    var activity: any ActivityProviding

    static var live: AppDependencies {
        AppDependencies(planner: .live(), activity: HealthKitActivityProvider())
    }

    static var preview: AppDependencies {
        let calendar = Calendar.current
        let window = DayStamp(.now).trailingWindow(7, calendar: calendar)
        let activity = zip(window, [6_200, 8_900, 4_300, 11_200, 7_700, 9_400, 5_100]).map {
            DailyActivity(day: $0, steps: $1, activeEnergy: $1 / 20)
        }
        return AppDependencies(
            planner: CoachPlanner(
                availability: PreviewAvailability(),
                modelPlanner: RuleBasedPlanner(),
                fallback: RuleBasedPlanner()
            ),
            activity: StaticActivityProvider(result: activity)
        )
    }
}

private struct PreviewAvailability: PlannerAvailabilityProviding {
    var availability: PlannerAvailability { .unavailable(.other) }
}
