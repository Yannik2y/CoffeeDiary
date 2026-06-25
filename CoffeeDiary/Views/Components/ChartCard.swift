import SwiftUI

struct ChartCard<Content: View>: View {
    let title: String
    let insight: String
    let minimumSamples: Int
    let sampleCount: Int
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                if !insight.isEmpty {
                    Text(insight)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            if sampleCount < minimumSamples {
                ContentUnavailableView(
                    "Not enough data".localized,
                    systemImage: "chart.bar.xaxis",
                    description: Text("Need at least %d brews.".localized(with: minimumSamples))
                )
                .frame(height: 160)
            } else {
                content()
            }
        }
        .padding(16)
        .cardStyle(cornerRadius: 16)
    }
}

struct KPIGrid: View {
    let stats: [KPIStat]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(stats) { stat in
                VStack(alignment: .leading, spacing: 6) {
                    Text(stat.title)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                    Text(stat.value)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                    if let delta = stat.delta {
                        Text(delta)
                            .font(.caption2)
                            .foregroundStyle(AppTheme.accentSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .cardStyle(cornerRadius: 14)
            }
        }
    }
}
