import SwiftUI

struct ModelPickerView: View {
    @Environment(\.dismiss) private var dismiss

    let category: EquipmentCategory
    let preferredBrandId: String?
    let selectedModelId: String?
    let onSelect: (EquipmentModel) -> Void

    @State private var searchText = ""

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

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

    private var otherBrands: [CoffeeBrand] {
        EquipmentCatalog.brands(for: category).filter { $0.id != preferredBrandId }
    }

    var body: some View {
        NavigationStack {
            List {
                if isSearching {
                    if searchResults.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                    } else {
                        ForEach(searchResults) { model in
                            modelRow(model, showBrand: true)
                        }
                    }
                } else {
                    if let preferredBrand, !preferredModels.isEmpty {
                        Section(preferredBrand.name) {
                            ForEach(preferredModels) { model in
                                modelRow(model, showBrand: false)
                            }
                        }
                    }
                    ForEach(otherBrands) { brand in
                        Section(brand.name) {
                            ForEach(EquipmentCatalog.models(for: category, brandId: brand.id)) { model in
                                modelRow(model, showBrand: false)
                            }
                        }
                    }
                    Section {
                        EmptyView()
                    } footer: {
                        Text("Model not listed? Close and type it in the Model field.".localized)
                    }
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
