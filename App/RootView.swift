import SwiftUI

struct RootView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        TabView(selection: $router.tab) {
            Tab("Today", systemImage: "checklist", value: AppTab.today) {
                NavigationStack(path: $router.todayPath) {
                    TodayView()
                        .navigationDestination(for: UUID.self) { HabitDetailView(habitID: $0) }
                }
            }
            Tab("Coach", systemImage: "sparkles", value: AppTab.coach) {
                NavigationStack { CoachView() }
            }
            Tab("Workouts", systemImage: "figure.run", value: AppTab.workouts) {
                NavigationStack { WorkoutsView() }
            }
        }
        .tint(.teal)
    }
}
