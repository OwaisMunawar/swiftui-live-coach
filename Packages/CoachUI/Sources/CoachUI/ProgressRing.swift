import SwiftUI

public struct ProgressRing: View {
    private let progress: Double
    private let lineWidth: CGFloat
    private let tint: Color

    public init(progress: Double, lineWidth: CGFloat = 10, tint: Color = .accentColor) {
        self.progress = min(max(progress, 0), 1)
        self.lineWidth = lineWidth
        self.tint = tint
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.18), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(tint.gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.5), value: progress)
        }
        .accessibilityElement()
        .accessibilityValue(Text(progress, format: .percent.precision(.fractionLength(0))))
    }
}

#Preview {
    ProgressRing(progress: 0.6, tint: .teal)
        .frame(width: 120, height: 120)
        .padding()
}
