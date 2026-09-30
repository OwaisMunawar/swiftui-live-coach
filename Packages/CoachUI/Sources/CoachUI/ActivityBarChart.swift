import Charts
import CoachCore
import SwiftUI

public struct ActivityBarChart: View {
    private let activity: [DailyActivity]
    private let calendar: Calendar

    public init(activity: [DailyActivity], calendar: Calendar = .current) {
        self.activity = activity
        self.calendar = calendar
    }

    public var body: some View {
        Chart(activity) { day in
            BarMark(
                x: .value("Day", day.day.noon(in: calendar), unit: .day),
                y: .value("Steps", day.steps)
            )
            .foregroundStyle(Color.green.gradient)
            .cornerRadius(4)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 3))
        }
        .accessibilityLabel("Steps over the last week")
    }
}
