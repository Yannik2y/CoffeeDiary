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

    /// Flat list rows avoid nested `ForEach { Section { ForEach } }`, which Xcode 16.4
    /// mis-resolves as `Charts.ChartContentBuilder` when Charts is linked in the target.
    fileprivate enum BrowseItem: Identifiable {
        case brandHeader(id: String, name: String)
        case model(EquipmentModel)

        var id: String {
            switch self {
            case .brandHeader(let id, _): return "header-\(id)"
            case .model(let model): return "model-\(model.id)"
            }
        }
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

    private var preferredBrowseItems: [BrowseItem] {
        guard let preferredBrand, !preferredModels.isEmpty else { return [] }
        return [.brandHeader(id: preferredBrand.id, name: preferredBrand.name)]
            + preferredModels.map { .model($0) }
    }

    private var otherBrowseItems: [BrowseItem] {
        EquipmentCatalog.brands(for: category)
            .filter { $0.id != preferredBrandId }
            .flatMap { brand -> [BrowseItem] in
                let models = EquipmentCatalog.models(for: category, brandId: brand.id)
                guard !models.isEmpty else { return [] }
                return [.brandHeader(id: brand.id, name: brand.name)]
                    + models.map { .model($0) }
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
        if !preferredBrowseItems.isEmpty {
            Section {
                ForEach(preferredBrowseItems) { item in
                    ModelPickerBrowseRow(
                        item: item,
                        selectedModelId: selectedModelId,
                        onSelect: selectModel
                    )
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
        } else if !otherBrowseItems.isEmpty {
            Section {
                ForEach(otherBrowseItems) { item in
                    ModelPickerBrowseRow(
                        item: item,
                        selectedModelId: selectedModelId,
                        onSelect: selectModel
                    )
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

    private func selectModel(_ model: EquipmentModel) {
        onSelect(model)
        dismiss()
    }
}

private struct ModelPickerBrowseRow: View {
    let item: ModelPickerView.BrowseItem
    let selectedModelId: String?
    let onSelect: (EquipmentModel) -> Void

    var body: some View {
        switch item {
        case .brandHeader(_, let name):
            Text(name)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 4, trailing: 20))
                .accessibilityAddTraits(.isHeader)
        case .model(let model):
            ModelPickerRow(
                model: model,
                showBrand: false,
                isSelected: selectedModelId == model.id,
                onSelect: onSelect
            )
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
