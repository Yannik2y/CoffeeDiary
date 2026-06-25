import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers
import UIKit

struct GrinderFormView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let grinder: Grinder?
    private let onSave: (Grinder) -> Void
    
    @State private var name: String
    @State private var brand: String
    @State private var burrType: String
    @State private var defaultSetting: Double
    @State private var notes: String
    @State private var photoData: Data?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showingDocumentPicker = false
    @State private var showingCamera = false
    @State private var brandId: String?
    @State private var isActive: Bool
    @State private var showingBrandPicker = false
    @State private var attachmentError: String?
    
    private let attachmentLimitBytes = 8 * 1024 * 1024
    private var cameraAvailable: Bool { UIImagePickerController.isSourceTypeAvailable(.camera) }
    
    init(grinder: Grinder? = nil, onSave: @escaping (Grinder) -> Void) {
        self.grinder = grinder
        self.onSave = onSave
        _name = State(initialValue: grinder?.name ?? "")
        _brand = State(initialValue: grinder?.brand ?? "")
        _burrType = State(initialValue: grinder?.burrType ?? "")
        _defaultSetting = State(initialValue: grinder?.defaultSetting ?? 0)
        _notes = State(initialValue: grinder?.notes ?? "")
        _photoData = State(initialValue: grinder?.displayPhotoData)
        _brandId = State(initialValue: grinder?.brandId)
        _isActive = State(initialValue: grinder?.isActive ?? false)
    }
    
    private var isEditing: Bool { grinder != nil }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Grinder".localized) {
                    TextField("Name".localized, text: $name)
                    HStack {
                        TextField("Brand".localized, text: $brand)
                        Button("Pick".localized) { showingBrandPicker = true }
                    }
                    TextField("Burr Type".localized, text: $burrType)
                    Stepper(value: $defaultSetting, in: 0...100, step: 0.1) {
                        Text("Default Setting: %.1f".localized(with: defaultSetting))
                    }
                    Toggle("Active Station".localized, isOn: $isActive)
                }

                Section("Photo / Documents".localized) {
                    if let photoData,
                       let image = UIImage(data: photoData) {
                        VStack(spacing: 8) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 180)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppTheme.accentSecondary.opacity(0.2), lineWidth: 1)
                                )
                            Button("Remove Photo", role: .destructive) {
                                self.photoData = nil
                            }
                        }
                    }
                    
                    PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()) {
                        Label(photoData == nil ? "Add Photo" : "Replace Photo", systemImage: "photo.on.rectangle")
                    }
                    
                    if cameraAvailable {
                        Button {
                            showingCamera = true
                        } label: {
                            Label("Take Photo", systemImage: "camera")
                        }
                    }
                    
                    Button {
                        showingDocumentPicker = true
                    } label: {
                        Label("Import Document", systemImage: "doc")
                    }
                    
                    if let attachmentError {
                        Text(attachmentError)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                
                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                }
            }
            .sheet(isPresented: $showingBrandPicker) {
                BrandPickerView(selectedBrandId: $brandId, brandName: $brand)
            }
            .navigationTitle(isEditing ? "Edit Grinder".localized : "New Grinder".localized)
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
            .onChange(of: selectedPhoto) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        await MainActor.run {
                            handleAttachmentData(data)
                        }
                    }
                }
            }
            .fileImporter(isPresented: $showingDocumentPicker, allowedContentTypes: [.image, .pdf]) { result in
                switch result {
                case .success(let url):
                    let accessing = url.startAccessingSecurityScopedResource()
                    defer {
                        if accessing { url.stopAccessingSecurityScopedResource() }
                    }
                    if let data = try? Data(contentsOf: url) {
                        handleAttachmentData(data)
                    }
                case .failure:
                    break
                }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraCaptureView(onCapture: { data in
                    handleAttachmentData(data)
                    showingCamera = false
                }, onDismiss: {
                    showingCamera = false
                })
            }
        }
    }
    
    private func save() {
        if let grinder {
            grinder.name = name
            grinder.brand = brand.isEmpty ? nil : brand
            grinder.burrType = burrType.isEmpty ? nil : burrType
            grinder.notes = notes.isEmpty ? nil : notes
            grinder.defaultSetting = defaultSetting == 0 ? nil : defaultSetting
            grinder.photoData = photoData.flatMap { PhotoStorage.compressedJPEG(from: $0) }
            grinder.photoPath = nil
            grinder.brandId = brandId
            grinder.isActive = isActive
            onSave(grinder)
        } else {
            let compressedPhoto = photoData.flatMap { PhotoStorage.compressedJPEG(from: $0) }
            let newGrinder = Grinder(
                name: name,
                brand: brand.isEmpty ? nil : brand,
                burrType: burrType.isEmpty ? nil : burrType,
                notes: notes.isEmpty ? nil : notes,
                defaultSetting: defaultSetting == 0 ? nil : defaultSetting,
                photoData: compressedPhoto,
                photoPath: nil,
                isActive: isActive,
                brandId: brandId
            )
            onSave(newGrinder)
        }
    }
    
    private func handleAttachmentData(_ data: Data) {
        if data.count > attachmentLimitBytes {
            attachmentError = "Files must be smaller than 8 MB."
            return
        }
        attachmentError = nil
        photoData = data
    }
}


