import SwiftUI

enum AppTheme {
    // Espresso palette - optimized for contrast (WCAG AA compliant)
    // Primary accent (Espresso): #6F4E37 - meets 4.5:1 on light backgrounds
    static let accent: Color = Color(red: 0x6F/255.0, green: 0x4E/255.0, blue: 0x37/255.0)
    // Secondary accent (Crema): #C19277
    static let accentSecondary: Color = Color(red: 0xC1/255.0, green: 0x92/255.0, blue: 0x77/255.0)
    // Background (Foam): Adaptive - light beige in light mode, dark in dark mode
    static let subtleBackground: Color = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0x11/255.0, green: 0x11/255.0, blue: 0x11/255.0, alpha: 1.0)
            : UIColor(red: 0xF6/255.0, green: 0xF4/255.0, blue: 0xF2/255.0, alpha: 1.0)
    })
    // Card (elevated): Proper elevation with better contrast in dark mode
    // In dark mode, we use a lighter gray to create clear elevation hierarchy
    // In light mode, we use pure white for maximum contrast
    static let cardBackground: Color = Color(uiColor: UIColor { traitCollection in
        if traitCollection.userInterfaceStyle == .dark {
            // Use a lighter gray (#2C2C2E) for clear separation from background (#111111)
            // This creates proper visual elevation - cards appear to "float" above the background
            return UIColor(red: 0x2C/255.0, green: 0x2C/255.0, blue: 0x2E/255.0, alpha: 1.0)
        } else {
            return UIColor.systemBackground  // White in light mode
        }
    })
    
    // Card shadow color - adaptive for both modes
    static var cardShadow: Color {
        Color(uiColor: UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                // Lighter shadow in dark mode for visibility
                return UIColor.black.withAlphaComponent(0.4)
            } else {
                return UIColor.black.withAlphaComponent(0.08)
            }
        })
    }
    // Text colors - Adaptive system colors for proper contrast in both modes
    static let textPrimary: Color = Color(uiColor: UIColor.label)
    static let textSecondary: Color = Color(uiColor: UIColor.secondaryLabel)
    // Status colors - using system colors for better adaptation
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
                    .shadow(color: AppTheme.cardShadow, radius: 12, x: 0, y: 4)
            )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.accent.opacity(configuration.isPressed ? 0.85 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

extension View {
    func cardStyle(cornerRadius: CGFloat = 18) -> some View {
        modifier(CardStyle(cornerRadius: cornerRadius))
    }
}


