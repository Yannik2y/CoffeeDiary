import SwiftUI
import SwiftData

struct BeanFormView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let bean: Bean?
    private let onSave: (Bean) -> Void
    
    @State private var name: String
    @State private var roaster: String
    @State private var origin: String
    @State private var process: String
    @State private var variety: String
    @State private var notes: String
    @State private var isFavorite: Bool
    @State private var isArchived: Bool
    @State private var photoData: Data?
    @State private var attachmentError: String?
    @State private var arabicaPercentage: Double
    
    init(bean: Bean? = nil, onSave: @escaping (Bean) -> Void) {
        self.bean = bean
        self.onSave = onSave
        _name = State(initialValue: bean?.name ?? "")
        _roaster = State(initialValue: bean?.roaster ?? "")
        _origin = State(initialValue: bean?.origin ?? "")
        _process = State(initialValue: bean?.process ?? "")
        _variety = State(initialValue: bean?.variety ?? "")
        _notes = State(initialValue: bean?.notes ?? "")
        _isFavorite = State(initialValue: bean?.isFavorite ?? false)
        _isArchived = State(initialValue: bean?.isArchived ?? false)
        _photoData = State(initialValue: bean?.displayPhotoData)
        _arabicaPercentage = State(initialValue: bean?.arabicaPercentage ?? 100)
    }
    
    private var isEditing: Bool { bean != nil }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Bean".localized) {
                    TextField("Name", text: $name)
                    TextField("Roaster", text: $roaster)
                    TextField("Origin", text: $origin)
                    TextField("Process", text: $process)
                    TextField("Variety", text: $variety)
                    Toggle("Favorite".localized, isOn: $isFavorite)
                    Toggle("Archived".localized, isOn: $isArchived)
                }
                
                EquipmentPhotoPicker(photoData: $photoData, attachmentError: $attachmentError)
                
                Section("Blend".localized) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Arabica")
                            Spacer()
                            Text("\(Int(arabicaPercentage))%")
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        Slider(value: $arabicaPercentage, in: 0...100, step: 1)
                        HStack {
                            Text("Robusta")
                            Spacer()
                            Text("\(Int(robustaPercentage))%")
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }
                
                Section("Notes".localized) {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                }
            }
            .navigationTitle(isEditing ? "Edit Bean" : "New Bean")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private var robustaPercentage: Double {
        max(0, 100 - arabicaPercentage)
    }
    
    private func save() {
        if let bean {
            bean.name = name
            bean.roaster = roaster.isEmpty ? nil : roaster
            bean.origin = origin.isEmpty ? nil : origin
            bean.process = process.isEmpty ? nil : process
            bean.variety = variety.isEmpty ? nil : variety
            bean.notes = notes.isEmpty ? nil : notes
            bean.isFavorite = isFavorite
            bean.isArchived = isArchived
            bean.photoData = photoData.flatMap { PhotoStorage.compressedJPEG(from: $0) }
            bean.photoPath = nil
            bean.arabicaPercentage = arabicaPercentage
            bean.robustaPercentage = robustaPercentage
            onSave(bean)
        } else {
            let compressedPhoto = photoData.flatMap { PhotoStorage.compressedJPEG(from: $0) }
            let newBean = Bean(
                name: name,
                roaster: roaster.isEmpty ? nil : roaster,
                origin: origin.isEmpty ? nil : origin,
                process: process.isEmpty ? nil : process,
                variety: variety.isEmpty ? nil : variety,
                notes: notes.isEmpty ? nil : notes,
                isFavorite: isFavorite,
                isArchived: isArchived,
                photoData: compressedPhoto,
                photoPath: nil,
                arabicaPercentage: arabicaPercentage,
                robustaPercentage: robustaPercentage
            )
            onSave(newBean)
        }
    }
}


