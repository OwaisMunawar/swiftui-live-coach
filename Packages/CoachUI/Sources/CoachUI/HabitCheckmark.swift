import SwiftUI

/// The round check used by habit rows in the app and the interactive widget.
/// Purely visual: wrap it in a `Button` and give that button the label.
public struct HabitCheckmark: View {
    private let isDone: Bool
    private let tint: Color
    @ScaledMetric(relativeTo: .title2) private var size: CGFloat = 30

    public init(isDone: Bool, tint: Color) {
        self.isDone = isDone
        self.tint = tint
    }

    public var body: some View {
        ZStack {
            Circle()
                .strokeBorder(tint.opacity(isDone ? 0 : 0.5), lineWidth: 2)
                .background(Circle().fill(isDone ? tint : .clear))
            Image(systemName: "checkmark")
                .font(.system(size: size * 0.45, weight: .bold))
                .foregroundStyle(.white)
                .opacity(isDone ? 1 : 0)
                .scaleEffect(isDone ? 1 : 0.4)
        }
        .frame(width: size, height: size)
        .contentShape(.circle)
        .animation(.bouncy(duration: 0.3), value: isDone)
        .accessibilityHidden(true)
    }
}

#Preview {
    HStack {
        HabitCheckmark(isDone: false, tint: .teal)
        HabitCheckmark(isDone: true, tint: .teal)
    }
    .padding()
}
