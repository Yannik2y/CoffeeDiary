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
                Section("Brewer") {
                    TextField("Name", text: $name)
                    TextField("Brand", text: $brand)
                    TextField("Style (e.g. V60, Chemex)", text: $style)
                    Toggle("Favorite", isOn: $isFavorite)
                }
                
                EquipmentPhotoPicker(photoData: $photoData, attachmentError: $attachmentError)
                
                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                }
            }
            .navigationTitle(isEditing ? "Edit Brewer" : "New Brewer")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
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
            compressedPhoto = await PhotoStorage.compressedJPEGAsync(from: photoData)
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
