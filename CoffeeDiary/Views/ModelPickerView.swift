import SwiftUI

struct ModelPickerView: View {
    @Environment(\.dismiss) private var dismiss

    let category: EquipmentCategory
    let preferredBrandId: String?
    let selectedModelId: String?
    let onSelect: (EquipmentModel) -> Void
    /// Called when the user wants to type the model themselves; carries the search text if any.
    let onCustom: (String?) -> Void

    @State private var searchText = ""
    @State private var showingAllBrands = false

    private struct BrandModels: Identifiable {
        let id: String
        let name: String
        let models: [EquipmentModel]
    }

    private var trimmedSearch: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isSearching: Bool { !trimmedSearch.isEmpty }

    private var searchResults: [EquipmentModel] {
        EquipmentCatalog.search(searchText, category: category)
    }

    private var preferredBrand: CoffeeBrand? {
        preferredBrandId.flatMap { BrandDatabase.brand(id: $0) }
    }

    private var preferredModels: [EquipmentModel] {
        guard let preferredBrandId else { return [] }
        return EquipmentCatalog.models(for: category, brandId: preferredBrandId)
    }

    /// With a brand that has catalog models, stay focused on that brand until the user expands.
    private var showsOnlyPreferredBrand: Bool {
        preferredBrand != nil && !preferredModels.isEmpty && !showingAllBrands
    }

    private var otherBrandModels: [BrandModels] {
        EquipmentCatalog.brands(for: category)
            .filter { $0.id != preferredBrandId }
            .map { brand in
                BrandModels(
                    id: brand.id,
                    name: brand.name,
                    models: EquipmentCatalog.models(for: category, brandId: brand.id)
                )
            }
    }

    var body: some View {
        NavigationStack {
            List {
                if isSearching {
                    searchSection
                } else {
                    browseSections
                }
            }
            .searchable(text: $searchText, prompt: Text("Search models".localized))
            .navigationTitle("Select Model".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized) { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private var searchSection: some View {
        if searchResults.isEmpty {
            Section {
                ContentUnavailableView {
                    Label("No matching model".localized, systemImage: "magnifyingglass")
                } description: {
                    Text("You can still add it as your own model.".localized)
                } actions: {
                    Button {
                        onCustom(trimmedSearch)
                        dismiss()
                    } label: {
                        Text("Use “%@” as model".localized(with: trimmedSearch))
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        } else {
            Section {
                ForEach(searchResults) { model in
                    ModelPickerRow(
                        model: model,
                        showBrand: true,
                        isSelected: selectedModelId == model.id,
                        onSelect: selectModel
                    )
                }
            }
            customRowSection
        }
    }

    @ViewBuilder
    private var browseSections: some View {
        if let preferredBrand, !preferredModels.isEmpty {
            // Separate View keeps Section+ForEach out of this ViewBuilder nesting
            // (Xcode 16.4 otherwise resolves nested ForEach to Charts.ChartContentBuilder).
            BrandModelsSection(
                name: preferredBrand.name,
                models: preferredModels,
                selectedModelId: selectedModelId,
                onSelect: selectModel
            )
        }

        if showsOnlyPreferredBrand {
            Section {
                Button {
                    withAnimation { showingAllBrands = true }
                } label: {
                    Label("Show other brands".localized, systemImage: "chevron.down")
                }
                .accessibilityIdentifier("modelPickerShowAllBrands")
            }
        } else {
            ForEach(otherBrandModels) { group in
                BrandModelsSection(
                    name: group.name,
                    models: group.models,
                    selectedModelId: selectedModelId,
                    onSelect: selectModel
                )
            }
        }

        customRowSection
    }

    private var customRowSection: some View {
        Section {
            Button {
                onCustom(nil)
                dismiss()
            } label: {
                Label("Enter model manually".localized, systemImage: "square.and.pencil")
            }
            .accessibilityIdentifier("modelPickerCustomRow")
        } footer: {
            Text("Model not listed? Type brand and model yourself; the build type sets the illustration.".localized)
        }
    }

    private func selectModel(_ model: EquipmentModel) {
        onSelect(model)
        dismiss()
    }
}

/// Isolated section view so nested List Section/ForEach type-checks as ViewBuilder,
/// not Charts.ChartContentBuilder, under Xcode 16.4.
private struct BrandModelsSection: View {
    let name: String
    let models: [EquipmentModel]
    let selectedModelId: String?
    let onSelect: (EquipmentModel) -> Void

    var body: some View {
        Section(name) {
            ForEach(models) { model in
                ModelPickerRow(
                    model: model,
                    showBrand: false,
                    isSelected: selectedModelId == model.id,
                    onSelect: onSelect
                )
            }
        }
    }
}

private struct ModelPickerRow: View {
    let model: EquipmentModel
    let showBrand: Bool
    let isSelected: Bool
    let onSelect: (EquipmentModel) -> Void

    var body: some View {
        Button {
            onSelect(model)
        } label: {
            HStack(spacing: 12) {
                EquipmentVisual(photoData: nil, silhouette: model.silhouette, cornerRadius: 10)
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(showBrand ? "\(model.brandName) \(model.name)" : model.name)
                        .foregroundStyle(Color.primary)
                    if let detail = detailText {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                        .accessibilityLabel("Selected".localized)
                }
            }
        }
        .accessibilityIdentifier("modelPickerRow_\(model.id)")
    }

    private var detailText: String? {
        let parts = [model.silhouette.title, model.burrDescription].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}
