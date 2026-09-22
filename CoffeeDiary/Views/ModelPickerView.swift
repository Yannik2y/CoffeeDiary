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

    private var otherBrands: [CoffeeBrand] {
        EquipmentCatalog.brands(for: category).filter { $0.id != preferredBrandId }
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
                    modelRow(model, showBrand: true)
                }
            }
            customRowSection
        }
    }

    @ViewBuilder
    private var browseSections: some View {
        if let preferredBrand, !preferredModels.isEmpty {
            Section(preferredBrand.name) {
                ForEach(preferredModels) { model in
                    modelRow(model, showBrand: false)
                }
            }
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
            ForEach(otherBrands) { brand in
                Section(brand.name) {
                    ForEach(EquipmentCatalog.models(for: category, brandId: brand.id)) { model in
                        modelRow(model, showBrand: false)
                    }
                }
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

    private func modelRow(_ model: EquipmentModel, showBrand: Bool) -> some View {
        Button {
            onSelect(model)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                EquipmentVisual(photoData: nil, silhouette: model.silhouette, cornerRadius: 10)
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(showBrand ? "\(model.brandName) \(model.name)" : model.name)
                        .foregroundStyle(Color.primary)
                    if let detail = detailText(for: model) {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                    }
                }

                Spacer()

                if selectedModelId == model.id {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                        .accessibilityLabel("Selected".localized)
                }
            }
        }
        .accessibilityIdentifier("modelPickerRow_\(model.id)")
    }

    private func detailText(for model: EquipmentModel) -> String? {
        let parts = [model.silhouette.title, model.burrDescription].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}
