import SwiftUI

enum AppTheme {
    /// Accent from the asset catalog (light/dark variants). Use as tint, not body text.
    static let accent: Color = .accentColor
    /// Secondary series/highlight color that adapts in light and dark.
    static let accentSecondary: Color = Color(.systemOrange)

    static let subtleBackground: Color = Color(.systemGroupedBackground)
    static let cardBackground: Color = Color(.secondarySystemBackground)

    static var cardShadow: Color {
        Color.primary.opacity(0.12)
    }

    static let textPrimary: Color = Color.primary
    static let textSecondary: Color = Color.secondary
    static let destructive: Color = .red
    static let success: Color = .green
}

struct CardStyle: ViewModifier {
    var cornerRadius: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppTheme.cardBackground)
                    .shadow(color: AppTheme.cardShadow.opacity(0.35), radius: 8, x: 0, y: 2)
            )
    }
}

extension View {
    func cardStyle(cornerRadius: CGFloat = 18) -> some View {
        modifier(CardStyle(cornerRadius: cornerRadius))
    }
}
