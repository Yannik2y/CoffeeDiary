import SwiftUI
import SwiftData

struct BeanFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var beans: [Bean]
    
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
    @State private var isSaving = false
    @State private var showingDuplicateWarning = false
    
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

    private var hasDuplicateName: Bool {
        EquipmentDuplicateName.hasDuplicate(
            candidate: name,
            existing: beans.map { ($0.id, $0.name) },
            excludingId: bean?.id
        )
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Bean".localized) {
                    TextField("Name".localized, text: $name)
                    TextField("Roaster".localized, text: $roaster)
                    TextField("Origin".localized, text: $origin)
                    TextField("Process".localized, text: $process)
                    TextField("Variety".localized, text: $variety)
                    Toggle("Favorite".localized, isOn: $isFavorite)
                    Toggle("Archived".localized, isOn: $isArchived)
                }
                
                EquipmentPhotoPicker(photoData: $photoData, attachmentError: $attachmentError)
                
                Section("Blend".localized) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Arabica".localized)
                            Spacer()
                            Text("\(Int(arabicaPercentage))%")
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        Slider(value: $arabicaPercentage, in: 0...100, step: 1)
                        HStack {
                            Text("Robusta".localized)
                            Spacer()
                            Text("\(Int(robustaPercentage))%")
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }
                
                Section("Notes".localized) {
                    TextField("Optional notes".localized, text: $notes, axis: .vertical)
                }
            }
            .navigationTitle(isEditing ? "Edit Bean".localized : "New Bean".localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save".localized : "Add".localized) {
                        DuplicateNameSaveAction.request(
                            hasDuplicate: hasDuplicateName,
                            presentWarning: $showingDuplicateWarning
                        ) {
                            Task { await save() }
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
            .duplicateNameSaveConfirmation(isPresented: $showingDuplicateWarning) {
                Task { await save() }
            }
        }
    }
    
    private var robustaPercentage: Double {
        max(0, 100 - arabicaPercentage)
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

        if let bean {
            bean.name = name
            bean.roaster = roaster.isEmpty ? nil : roaster
            bean.origin = origin.isEmpty ? nil : origin
            bean.process = process.isEmpty ? nil : process
            bean.variety = variety.isEmpty ? nil : variety
            bean.notes = notes.isEmpty ? nil : notes
            bean.isFavorite = isFavorite
            bean.isArchived = isArchived
            bean.photoData = compressedPhoto
            bean.photoPath = nil
            bean.arabicaPercentage = arabicaPercentage
            bean.robustaPercentage = robustaPercentage
            onSave(bean)
        } else {
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
        dismiss()
    }
}


