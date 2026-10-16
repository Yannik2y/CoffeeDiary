import SwiftUI
import SwiftData

struct BrewerFormView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let brewer: Brewer?
    private let onSave: (Brewer) -> Void
    
    @State private var name: String
    @State private var brand: String
    @State private var style: String
    @State private var notes: String
    @State private var isFavorite: Bool
    @State private var photoData: Data?
    @State private var attachmentError: String?
    @State private var isSaving = false
    
    init(brewer: Brewer? = nil, onSave: @escaping (Brewer) -> Void) {
        self.brewer = brewer
        self.onSave = onSave
        _name = State(initialValue: brewer?.name ?? "")
        _brand = State(initialValue: brewer?.brand ?? "")
        _style = State(initialValue: brewer?.style ?? "")
        _notes = State(initialValue: brewer?.notes ?? "")
        _isFavorite = State(initialValue: brewer?.isFavorite ?? false)
        _photoData = State(initialValue: brewer?.displayPhotoData)
    }
    
    private var isEditing: Bool { brewer != nil }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Brewer".localized) {
                    TextField("Name".localized, text: $name)
                    TextField("Brand".localized, text: $brand)
                    TextField("Style (e.g. V60, Chemex)".localized, text: $style)
                    Toggle("Favorite".localized, isOn: $isFavorite)
                }
                
                EquipmentPhotoPicker(photoData: $photoData, attachmentError: $attachmentError)
                
                Section("Notes".localized) {
                    TextField("Optional notes".localized, text: $notes, axis: .vertical)
                }
            }
            .navigationTitle(isEditing ? "Edit Brewer".localized : "New Brewer".localized)
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
        let compressedPhoto: Data?
        if let photoData {
            guard let compressed = await PhotoStorage.compressedJPEGAsync(from: photoData) else {
                attachmentError = "Couldn't process the photo. Please try another image.".localized
                return
            }
            compressedPhoto = compressed
        } else {
            compressedPhoto = nil
        }

        if let brewer {
            brewer.name = name
            brewer.brand = brand.isEmpty ? nil : brand
            brewer.style = style.isEmpty ? nil : style
            brewer.notes = notes.isEmpty ? nil : notes
            brewer.isFavorite = isFavorite
            brewer.photoData = compressedPhoto
            brewer.photoPath = nil
            onSave(brewer)
        } else {
            let newBrewer = Brewer(
                name: name,
                brand: brand.isEmpty ? nil : brand,
                style: style.isEmpty ? nil : style,
                notes: notes.isEmpty ? nil : notes,
                isFavorite: isFavorite,
                photoData: compressedPhoto,
                photoPath: nil
            )
            onSave(newBrewer)
        }
        dismiss()
    }
}
