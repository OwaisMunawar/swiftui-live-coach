import SwiftUI
import WidgetKit

@main
struct LiveCoachWidgets: WidgetBundle {
    var body: some Widget {
        TodayHabitsWidget()
        WorkoutLiveActivity()
    }
}
