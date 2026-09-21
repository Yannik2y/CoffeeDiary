import SwiftUI

/// A reusable star rating view that displays and allows editing of 0-5 star ratings
struct StarRatingView: View {
    @Binding var rating: Int
    let editable: Bool
    let size: CGFloat

    init(rating: Binding<Int>, editable: Bool = true, size: CGFloat = 24) {
        self._rating = rating
        self.editable = editable
        self.size = size
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(index <= rating ? AppTheme.accentSecondary : AppTheme.textSecondary.opacity(0.3))
                    .frame(width: size + 8, height: size + 8)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard editable else { return }
                        if rating == index {
                            rating = 0
                        } else {
                            rating = index
                        }
                        HapticFeedback.selection()
                    }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rating".localized)
        .accessibilityValue("%d of 5 stars".localized(with: rating))
        .accessibilityAdjustableAction { direction in
            guard editable else { return }
            switch direction {
            case .increment:
                rating = min(5, rating + 1)
            case .decrement:
                rating = max(0, rating - 1)
            @unknown default:
                break
            }
            HapticFeedback.selection()
        }
        .accessibilityHint(editable ? "Swipe up or down to change rating. Double tap a star to set or clear.".localized : "")
    }
}

/// Display-only star rating view
struct StarRatingDisplayView: View {
    let rating: Int
    let size: CGFloat

    init(rating: Int, size: CGFloat = 20) {
        self.rating = rating
        self.size = size
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(index <= rating ? AppTheme.accentSecondary : AppTheme.textSecondary.opacity(0.2))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rating".localized)
        .accessibilityValue("%d of 5 stars".localized(with: rating))
    }
}
