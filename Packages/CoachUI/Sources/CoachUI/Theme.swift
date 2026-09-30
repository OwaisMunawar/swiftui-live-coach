import CoachCore
import SwiftUI

extension HabitTint {
    public var color: Color {
        switch self {
        case .teal: .teal
        case .orange: .orange
        case .pink: .pink
        case .indigo: .indigo
        case .green: .green
        case .yellow: .yellow
        }
    }
}

extension WorkoutKind {
    public var color: Color {
        switch self {
        case .run: .orange
        case .strength: .indigo
        case .yoga: .teal
        case .walk: .green
        case .focus: .purple
        }
    }
}

public enum CoachMetrics {
    public static let cornerRadius: CGFloat = 22
    public static let cardPadding: CGFloat = 16
}

extension Color {
    /// Raised surface on top of a grouped background, in light and dark mode.
    public static var cardSurface: Color {
        #if os(iOS)
        Color(uiColor: .secondarySystemGroupedBackground)
        #else
        Color(nsColor: .controlBackgroundColor)
        #endif
    }
}

public struct CardBackground: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .padding(CoachMetrics.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardSurface, in: .rect(cornerRadius: CoachMetrics.cornerRadius))
    }
}

extension View {
    /// Standard grouped surface used by every screen.
    public func coachCard() -> some View {
        modifier(CardBackground())
    }
}
