import CoachCore
import SwiftUI

/// GitHub-style completion grid: one column per week, one row per weekday.
public struct HeatmapGrid: View {
    private let days: [DayStamp]
    private let completed: Set<DayStamp>
    private let tint: Color

    /// - Parameter days: Contiguous days, oldest first. Ideally a multiple of 7.
    public init(days: [DayStamp], completed: Set<DayStamp>, tint: Color) {
        self.days = days
        self.completed = completed
        self.tint = tint
    }

    public var body: some View {
        let weeks = stride(from: 0, to: days.count, by: 7).map { Array(days[$0..<min($0 + 7, days.count)]) }
        Grid(horizontalSpacing: 4, verticalSpacing: 4) {
            ForEach(0..<7, id: \.self) { row in
                GridRow {
                    ForEach(weeks.indices, id: \.self) { column in
                        let week = weeks[column]
                        let day = row < week.count ? week[row] : nil
                        RoundedRectangle(cornerRadius: 3)
                            .fill(day.map(completed.contains) == true ? AnyShapeStyle(tint) : AnyShapeStyle(.quaternary))
                            .opacity(day == nil ? 0 : 1)
                            .aspectRatio(1, contentMode: .fit)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Completion history")
        .accessibilityValue("\(days.filter(completed.contains).count) of \(days.count) days completed")
    }
}
