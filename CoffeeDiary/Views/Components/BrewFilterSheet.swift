import SwiftUI

struct BrewFilterSheet: View {
    @Binding var filterStartDate: Date?
    @Binding var filterEndDate: Date?
    @Binding var filterMinRatio: Double?
    @Binding var filterMaxRatio: Double?
    @Binding var filterMinRating: Int?
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Date".localized) {
                    DatePicker("From".localized, selection: Binding(
                        get: { filterStartDate ?? Date() },
                        set: { filterStartDate = $0 }
                    ), displayedComponents: .date)
                    if filterStartDate != nil {
                        Button("Clear start date".localized) { filterStartDate = nil }
                    }

                    DatePicker("To".localized, selection: Binding(
                        get: { filterEndDate ?? Date() },
                        set: { filterEndDate = $0 }
                    ), displayedComponents: .date)
                    if filterEndDate != nil {
                        Button("Clear end date".localized) { filterEndDate = nil }
                    }
                }

                Section("Brew Ratio".localized) {
                    Stepper(value: Binding(
                        get: { filterMinRatio ?? 0 },
                        set: { filterMinRatio = $0 > 0 ? $0 : nil }
                    ), in: 0...10, step: 0.1) {
                        Text("Min ratio: %@".localized(with: String(format: "%.1f", filterMinRatio ?? 0)))
                    }
                    Stepper(value: Binding(
                        get: { filterMaxRatio ?? 0 },
                        set: { filterMaxRatio = $0 > 0 ? $0 : nil }
                    ), in: 0...10, step: 0.1) {
                        Text("Max ratio: %@".localized(with: String(format: "%.1f", filterMaxRatio ?? 0)))
                    }
                    if filterMinRatio != nil || filterMaxRatio != nil {
                        Button("Clear ratio filters".localized) {
                            filterMinRatio = nil
                            filterMaxRatio = nil
                        }
                    }
                }

                Section("Rating".localized) {
                    Stepper(value: Binding(
                        get: { filterMinRating ?? 0 },
                        set: { filterMinRating = $0 > 0 ? $0 : nil }
                    ), in: 0...5, step: 1) {
                        if let minRating = filterMinRating, minRating > 0 {
                            HStack {
                                StarRatingDisplayView(rating: minRating, size: 16)
                                Text("and above".localized)
                            }
                        } else {
                            Text("Minimum rating".localized)
                        }
                    }
                    if let minRating = filterMinRating, minRating > 0 {
                        Button("Clear rating filter".localized) { filterMinRating = nil }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.subtleBackground)
            .navigationTitle("Filters".localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close".localized) { isPresented = false }
                }
            }
        }
    }
}
