import CoachCore
import SwiftData
import SwiftUI

@main
struct LiveCoachApp: App {
    @State private var router = AppRouter()
    @State private var health: HealthModel
    @State private var coach: CoachModel

    init() {
        let dependencies = AppDependencies.live
        _health = State(initialValue: HealthModel(provider: dependencies.activity))
        _coach = State(initialValue: CoachModel(planner: dependencies.planner))

        if ProcessInfo.processInfo.arguments.contains("-demoData") {
            // Seeds a deterministic dataset for screenshots and manual QA.
            try? DemoSeed.populate(SharedModelContainer.shared.mainContext)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(router)
                .environment(health)
                .environment(coach)
                .onOpenURL { router.handle($0, context: SharedModelContainer.shared.mainContext) }
                .task {
                    await WorkoutCoordinator(context: SharedModelContainer.shared.mainContext).reconcileActivities()
                    LiveCoachShortcuts.updateAppShortcutParameters()
                }
        }
        .modelContainer(SharedModelContainer.shared)
    }
}
