import SwiftUI

struct DialInBanner: View {
    let suggestion: DialInSuggestion

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Dial-in tip".localized, systemImage: "lightbulb.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
            Text(suggestion.message)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(cornerRadius: 14)
        .padding(.horizontal, 20)
    }
}
