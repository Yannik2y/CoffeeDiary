import SwiftUI

/// Large preview of the machine/grinder as it will appear in the Coffee Station.
struct EquipmentPreviewSection: View {
    let photoData: Data?
    let silhouette: EquipmentSilhouette

    var body: some View {
        Section {
            HStack {
                Spacer(minLength: 0)
                EquipmentVisual(photoData: photoData, silhouette: silhouette, cornerRadius: 20)
                    .frame(width: 140, height: 140)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 4)
            .listRowBackground(Color.clear)
        }
    }
}

/// Brand, model and build-type rows shared by the machine and grinder forms.
/// Picking a catalog model fills brand, model, silhouette and (if empty) the name.
struct EquipmentIdentityFields: View {
    let category: EquipmentCategory
    @Binding var name: String
    @Binding var brand: String
    @Binding var brandId: String?
    @Binding var modelName: String
    @Binding var modelId: String?
    @Binding var silhouetteId: String?
    var onCatalogModelSelected: ((EquipmentModel) -> Void)? = nil

    @State private var showingBrandPicker = false
    @State private var showingModelPicker = false
    @State private var openModelPickerAfterBrand = false
    @State private var focusModelFieldAfterPicker = false
    @FocusState private var modelFieldFocused: Bool

    private var resolvedSilhouette: EquipmentSilhouette {
        EquipmentSilhouette.resolve(silhouetteId: silhouetteId, modelId: modelId, category: category)
    }

    var body: some View {
        HStack {
            TextField("Brand".localized, text: $brand)
                .accessibilityIdentifier("equipmentBrandField")
            Button("Pick".localized) { showingBrandPicker = true }
                .accessibilityIdentifier("equipmentBrandPickButton")
        }

        HStack {
            TextField("Model".localized, text: $modelName)
                .focused($modelFieldFocused)
                .accessibilityIdentifier("equipmentModelField")
            Button("Pick".localized) { showingModelPicker = true }
                .accessibilityIdentifier("equipmentModelPickButton")
        }

        VStack(alignment: .leading, spacing: 8) {
            Text("Build Type".localized)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(EquipmentSilhouette.all(for: category)) { silhouette in
                        silhouetteTile(silhouette)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingBrandPicker, onDismiss: {
            // Presenting from onDismiss avoids the sheet-over-sheet race.
            if openModelPickerAfterBrand {
                openModelPickerAfterBrand = false
                showingModelPicker = true
            }
        }) {
            BrandPickerView(selectedBrandId: $brandId, brandName: $brand)
        }
        .sheet(isPresented: $showingModelPicker, onDismiss: {
            if focusModelFieldAfterPicker {
                focusModelFieldAfterPicker = false
                modelFieldFocused = true
            }
        }) {
            ModelPickerView(
                category: category,
                preferredBrandId: brandId,
                selectedModelId: modelId,
                onSelect: apply,
                onCustom: useCustomModel
            )
        }
        .onChange(of: brandId) { _, newBrandId in
            guard let newBrandId else { return }
            // A stale catalog model from another brand no longer applies.
            if let modelId, let model = EquipmentCatalog.model(id: modelId), model.brandId != newBrandId {
                self.modelId = nil
                modelName = ""
            }
            if showingBrandPicker, !EquipmentCatalog.models(for: category, brandId: newBrandId).isEmpty {
                openModelPickerAfterBrand = true
            }
        }
        .onChange(of: modelName) { _, newValue in
            // Free-text edits detach the entry from the catalog model.
            guard let modelId, let model = EquipmentCatalog.model(id: modelId) else { return }
            if model.name != newValue.trimmingCharacters(in: .whitespacesAndNewlines) {
                self.modelId = nil
            }
        }
    }

    private func silhouetteTile(_ silhouette: EquipmentSilhouette) -> some View {
        let isSelected = resolvedSilhouette == silhouette
        return Button {
            silhouetteId = silhouette.rawValue
        } label: {
            VStack(spacing: 6) {
                EquipmentVisual(photoData: nil, silhouette: silhouette, cornerRadius: 12)
                    .frame(width: 64, height: 64)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
                Text(silhouette.title)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 72)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(silhouette.title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityIdentifier("silhouetteTile_\(silhouette.rawValue)")
    }

    private func useCustomModel(_ typed: String?) {
        modelId = nil
        if let typed, !typed.isEmpty {
            modelName = typed
            if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                name = typed
            }
        } else {
            focusModelFieldAfterPicker = true
        }
    }

    private func apply(_ model: EquipmentModel) {
        modelId = model.id
        modelName = model.name
        silhouetteId = model.silhouette.rawValue
        brandId = model.brandId
        brand = model.brandName
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            name = model.name
        }
        onCatalogModelSelected?(model)
    }
}
