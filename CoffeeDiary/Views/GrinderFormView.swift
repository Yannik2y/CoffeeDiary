import SwiftUI
import SwiftData

struct GrinderFormView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let grinder: Grinder?
    private let onSave: (Grinder) -> Void
    
    @State private var name: String
    @State private var brand: String
    @State private var modelName: String
    @State private var burrType: String
    @State private var defaultSetting: Double
    @State private var notes: String
    @State private var photoData: Data?
    @State private var brandId: String?
    @State private var modelId: String?
    @State private var silhouetteId: String?
    @State private var isActive: Bool
    @State private var attachmentError: String?
    @State private var isSaving = false
    
    init(grinder: Grinder? = nil, onSave: @escaping (Grinder) -> Void) {
        self.grinder = grinder
        self.onSave = onSave
        _name = State(initialValue: grinder?.name ?? "")
        _brand = State(initialValue: grinder?.brand ?? "")
        _modelName = State(initialValue: grinder?.model ?? "")
        _burrType = State(initialValue: grinder?.burrType ?? "")
        _defaultSetting = State(initialValue: grinder?.defaultSetting ?? 0)
        _notes = State(initialValue: grinder?.notes ?? "")
        _photoData = State(initialValue: grinder?.displayPhotoData)
        _brandId = State(initialValue: grinder?.brandId)
        _modelId = State(initialValue: grinder?.modelId)
        _silhouetteId = State(initialValue: grinder?.silhouetteId)
        _isActive = State(initialValue: grinder?.isActive ?? false)
    }
    
    private var isEditing: Bool { grinder != nil }

    private var silhouette: EquipmentSilhouette {
        EquipmentSilhouette.resolve(silhouetteId: silhouetteId, modelId: modelId, category: .grinder)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                EquipmentPreviewSection(photoData: photoData, silhouette: silhouette)

                Section("Grinder".localized) {
                    TextField("Name".localized, text: $name)
                    EquipmentIdentityFields(
                        category: .grinder,
                        name: $name,
                        brand: $brand,
                        brandId: $brandId,
                        modelName: $modelName,
                        modelId: $modelId,
                        silhouetteId: $silhouetteId,
                        onCatalogModelSelected: { model in
                            if burrType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                               let burrDescription = model.burrDescription {
                                burrType = burrDescription
                            }
                        }
                    )
                    TextField("Burr Type".localized, text: $burrType)
                    Stepper(value: $defaultSetting, in: 0...100, step: 0.1) {
                        Text("Default Setting: %.1f".localized(with: defaultSetting))
                    }
                    Toggle("Active Station".localized, isOn: $isActive)
                }

                EquipmentPhotoPicker(photoData: $photoData, attachmentError: $attachmentError)
                
                Section("Notes".localized) {
                    TextField("Optional notes".localized, text: $notes, axis: .vertical)
                }
            }
            .navigationTitle(isEditing ? "Edit Grinder".localized : "New Grinder".localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save".localized : "Add".localized) {
                        Task { await save() }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
        }
    }
    
    private func save() async {
        isSaving = true
        defer { isSaving = false }
        let trimmedBrand = brand.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedModel = modelName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBurr = burrType.trimmingCharacters(in: .whitespacesAndNewlines)
        let compressedPhoto: Data?
        if let photoData {
            compressedPhoto = await PhotoStorage.compressedJPEGAsync(from: photoData)
        } else {
            compressedPhoto = nil
        }

        if let grinder {
            grinder.name = name
            grinder.brand = trimmedBrand.isEmpty ? nil : trimmedBrand
            grinder.model = trimmedModel.isEmpty ? nil : trimmedModel
            grinder.burrType = trimmedBurr.isEmpty ? nil : trimmedBurr
            grinder.notes = notes.isEmpty ? nil : notes
            grinder.defaultSetting = defaultSetting == 0 ? nil : defaultSetting
            grinder.photoData = compressedPhoto
            grinder.photoPath = nil
            grinder.brandId = brandId
            grinder.modelId = modelId
            grinder.silhouetteId = silhouetteId
            grinder.isActive = isActive
            onSave(grinder)
        } else {
            let newGrinder = Grinder(
                name: name,
                brand: trimmedBrand.isEmpty ? nil : trimmedBrand,
                burrType: trimmedBurr.isEmpty ? nil : trimmedBurr,
                notes: notes.isEmpty ? nil : notes,
                defaultSetting: defaultSetting == 0 ? nil : defaultSetting,
                photoData: compressedPhoto,
                photoPath: nil,
                isActive: isActive,
                brandId: brandId,
                model: trimmedModel.isEmpty ? nil : trimmedModel,
                modelId: modelId,
                silhouetteId: silhouetteId
            )
            onSave(newGrinder)
        }
        dismiss()
    }
}
