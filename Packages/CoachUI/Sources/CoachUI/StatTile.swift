import SwiftUI

public struct StatTile: View {
    private let title: String
    private let value: String
    private let symbol: String
    private let tint: Color
    private let spokenValue: String?

    /// - Parameter spokenValue: What VoiceOver reads instead of `value`, for
    ///   values that are terse on screen (e.g. "12" meaning "12 days").
    public init(title: String, value: String, symbol: String, tint: Color, spokenValue: String? = nil) {
        self.title = title
        self.value = value
        self.symbol = symbol
        self.tint = tint
        self.spokenValue = spokenValue
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: symbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
                .lineLimit(1)
            Text(value)
                .font(.title2.bold())
                .monospacedDigit()
                .contentTransition(.numericText())
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .coachCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(spokenValue ?? value)
    }
}

#Preview {
    StatTile(title: "Streak", value: "12 days", symbol: "flame.fill", tint: .orange)
        .padding()
}
