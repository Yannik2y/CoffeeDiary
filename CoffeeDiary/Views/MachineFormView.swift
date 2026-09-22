import SwiftUI
import SwiftData

struct MachineFormView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let machine: Machine?
    private let onSave: (Machine) -> Void
    
    @State private var name: String
    @State private var brand: String
    @State private var modelName: String
    @State private var notes: String
    @State private var photoData: Data?
    @State private var brandId: String?
    @State private var modelId: String?
    @State private var silhouetteId: String?
    @State private var isActive: Bool
    @State private var attachmentError: String?
    
    init(machine: Machine? = nil, onSave: @escaping (Machine) -> Void) {
        self.machine = machine
        self.onSave = onSave
        _name = State(initialValue: machine?.name ?? "")
        _brand = State(initialValue: machine?.brand ?? "")
        _modelName = State(initialValue: machine?.model ?? "")
        _notes = State(initialValue: machine?.notes ?? "")
        _photoData = State(initialValue: machine?.displayPhotoData)
        _brandId = State(initialValue: machine?.brandId)
        _modelId = State(initialValue: machine?.modelId)
        _silhouetteId = State(initialValue: machine?.silhouetteId)
        _isActive = State(initialValue: machine?.isActive ?? false)
    }
    
    private var isEditing: Bool { machine != nil }

    private var silhouette: EquipmentSilhouette {
        EquipmentSilhouette.resolve(silhouetteId: silhouetteId, modelId: modelId, category: .machine)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                EquipmentPreviewSection(photoData: photoData, silhouette: silhouette)

                Section("Machine".localized) {
                    TextField("Name".localized, text: $name)
                    EquipmentIdentityFields(
                        category: .machine,
                        name: $name,
                        brand: $brand,
                        brandId: $brandId,
                        modelName: $modelName,
                        modelId: $modelId,
                        silhouetteId: $silhouetteId
                    )
                    Toggle("Active Station".localized, isOn: $isActive)
                }
                
                EquipmentPhotoPicker(photoData: $photoData, attachmentError: $attachmentError)
                
                Section("Notes".localized) {
                    TextField("Optional notes".localized, text: $notes, axis: .vertical)
                }
            }
            .navigationTitle(isEditing ? "Edit Machine".localized : "New Machine".localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save".localized : "Add".localized) {
                        save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func save() {
        let trimmedBrand = brand.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedModel = modelName.trimmingCharacters(in: .whitespacesAndNewlines)
        let compressedPhoto = photoData.flatMap { PhotoStorage.compressedJPEG(from: $0) }

        if let machine {
            machine.name = name
            machine.brand = trimmedBrand.isEmpty ? nil : trimmedBrand
            machine.model = trimmedModel.isEmpty ? nil : trimmedModel
            machine.notes = notes.isEmpty ? nil : notes
            machine.photoData = compressedPhoto
            machine.photoPath = nil
            machine.brandId = brandId
            machine.modelId = modelId
            machine.silhouetteId = silhouetteId
            machine.isActive = isActive
            onSave(machine)
        } else {
            let newMachine = Machine(
                name: name,
                brand: trimmedBrand.isEmpty ? nil : trimmedBrand,
                model: trimmedModel.isEmpty ? nil : trimmedModel,
                notes: notes.isEmpty ? nil : notes,
                photoData: compressedPhoto,
                photoPath: nil,
                isActive: isActive,
                brandId: brandId,
                modelId: modelId,
                silhouetteId: silhouetteId
            )
            onSave(newMachine)
        }
    }
}
