import SwiftUI

struct ChartCard<Content: View>: View {
    let title: String
    let insight: String
    let minimumSamples: Int
    let sampleCount: Int
    var explanation: String? = nil
    @ViewBuilder let content: () -> Content

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showingExplanation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    if explanation != nil {
                        Button {
                            showingExplanation = true
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.body)
                                .foregroundStyle(Color.accentColor)
                                .symbolRenderingMode(.hierarchical)
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("Chart explanation".localized)
                        .accessibilityHint("Shows what this chart means.".localized)
                    }
                }

                if !insight.isEmpty {
                    Text(insight)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
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
        .modifier(
            ChartExplanationPresentation(
                title: title,
                explanation: explanation,
                isPresented: $showingExplanation,
                prefersPopover: horizontalSizeClass == .regular
            )
        )
    }
}

/// Compact width: sheet (readable, Dynamic Type). Regular width: popover anchored to the card.
private struct ChartExplanationPresentation: ViewModifier {
    let title: String
    let explanation: String?
    @Binding var isPresented: Bool
    let prefersPopover: Bool

    func body(content: Content) -> some View {
        if prefersPopover {
            content
                .popover(isPresented: $isPresented, arrowEdge: .top) {
                    if let explanation {
                        ChartExplanationBody(text: explanation)
                            .padding()
                            .frame(minWidth: 280, idealWidth: 320, maxWidth: 360)
                            .presentationCompactAdaptation(.popover)
                    }
                }
        } else {
            content
                .sheet(isPresented: $isPresented) {
                    if let explanation {
                        NavigationStack {
                            ScrollView {
                                ChartExplanationBody(text: explanation)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                            }
                            .background(AppTheme.subtleBackground)
                            .navigationTitle(title)
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .confirmationAction) {
                                    Button("Done".localized) {
                                        isPresented = false
                                    }
                                }
                            }
                        }
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                    }
                }
        }
    }
}

private struct ChartExplanationBody: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.body)
            .foregroundStyle(AppTheme.textPrimary)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .textSelection(.enabled)
            .accessibilityLabel(text)
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
                            .foregroundStyle(Color.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .cardStyle(cornerRadius: 14)
            }
        }
    }
}
