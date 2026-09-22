import SwiftUI

struct BrewRow: View {
    let entry: BrewEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(entry.coffeeName)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)

                if entry.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.system(.caption, weight: .medium))
                        .foregroundStyle(.yellow)
                }

                if entry.rating > 0 {
                    StarRatingDisplayView(rating: entry.rating, size: 12)
                }

                Spacer(minLength: 8)

                Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(.subheadline, design: .rounded, weight: .regular))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(.bottom, 12)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    MetricBadge(
                        icon: entry.brewStyle == .espresso ? "cup.and.saucer.fill" : "drop.fill",
                        text: entry.brewStyle.title,
                        color: AppTheme.accent
                    )
                    if entry.brewStyle == .espresso {
                        MetricBadge(
                            icon: "cup.and.saucer",
                            text: entry.shotType.displayName,
                            color: AppTheme.accentSecondary
                        )
                    }
                }
                HStack(spacing: 6) {
                    MetricBadge(
                        icon: "arrow.left.arrow.right",
                        text: Formatters.ratioString(dose: entry.doseGrams, yield: entry.yieldGrams),
                        color: AppTheme.accentSecondary
                    )
                    MetricBadge(
                        icon: "dial.medium.fill",
                        text: String(format: "%.1f", entry.grinderSetting),
                        color: AppTheme.accent
                    )
                }
            }
            .padding(.bottom, entry.bean != nil || entry.grinder != nil || entry.brewer != nil ? 10 : 0)

            if entry.bean != nil || entry.grinder != nil || entry.brewer != nil {
                HStack(spacing: 10) {
                    if let bean = entry.bean {
                        EquipmentTag(icon: "leaf.fill", text: bean.name)
                    }
                    if let grinder = entry.grinder {
                        EquipmentTag(icon: "gearshape.fill", text: grinder.name)
                    }
                    if let brewer = entry.brewer {
                        EquipmentTag(icon: "drop.fill", text: brewer.name)
                    }
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        "\(entry.coffeeName), \(entry.shotType.displayName), ratio \(Formatters.ratioString(dose: entry.doseGrams, yield: entry.yieldGrams)), rating \(entry.rating), date \(entry.createdAt.formatted(date: .abbreviated, time: .shortened))"
    }
}

struct MetricBadge: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(.caption2, weight: .semibold))
                .foregroundStyle(color)
            Text(text)
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color(.secondarySystemFill))
        )
        .accessibilityLabel(text)
    }
}

struct EquipmentTag: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(.caption2, weight: .medium))
            Text(text)
                .font(.system(.caption, design: .rounded, weight: .regular))
        }
        .foregroundStyle(AppTheme.textSecondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(AppTheme.textSecondary.opacity(0.08)))
    }
}

struct FilterChip: View {
    let text: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(text)
                .font(.caption)
                .foregroundStyle(AppTheme.textPrimary)
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2.bold())
            }
            .buttonStyle(.plain)
            .foregroundStyle(AppTheme.textSecondary)
            .accessibilityLabel("Remove filter".localized)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(AppTheme.cardBackground)
                .shadow(color: AppTheme.cardShadow.opacity(0.15), radius: 2, x: 0, y: 1)
        )
        .overlay(Capsule().stroke(AppTheme.accent.opacity(0.25), lineWidth: 0.5))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
    }
}
