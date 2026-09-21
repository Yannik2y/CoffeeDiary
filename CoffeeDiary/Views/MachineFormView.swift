import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers
import UIKit

struct MachineFormView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let machine: Machine?
    private let onSave: (Machine) -> Void
    
    @State private var name: String
    @State private var brand: String
    @State private var modelName: String
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
    
    init(machine: Machine? = nil, onSave: @escaping (Machine) -> Void) {
        self.machine = machine
        self.onSave = onSave
        _name = State(initialValue: machine?.name ?? "")
        _brand = State(initialValue: machine?.brand ?? "")
        _modelName = State(initialValue: machine?.model ?? "")
        _notes = State(initialValue: machine?.notes ?? "")
        _photoData = State(initialValue: machine?.displayPhotoData)
        _brandId = State(initialValue: machine?.brandId)
        _isActive = State(initialValue: machine?.isActive ?? false)
    }
    
    private var isEditing: Bool { machine != nil }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Machine".localized) {
                    TextField("Name".localized, text: $name)
                    HStack {
                        TextField("Brand".localized, text: $brand)
                        Button("Pick".localized) { showingBrandPicker = true }
                    }
                    TextField("Model".localized, text: $modelName)
                    Toggle("Active Station".localized, isOn: $isActive)
                }
                
                Section("Photo".localized) {
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
            .navigationTitle(isEditing ? "Edit Machine".localized : "New Machine".localized)
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
        if let machine {
            machine.name = name
            machine.brand = brand.isEmpty ? nil : brand
            machine.model = modelName.isEmpty ? nil : modelName
            machine.notes = notes.isEmpty ? nil : notes
            machine.photoData = photoData.flatMap { PhotoStorage.compressedJPEG(from: $0) }
            machine.photoPath = nil
            machine.brandId = brandId
            machine.isActive = isActive
            onSave(machine)
        } else {
            let compressedPhoto = photoData.flatMap { PhotoStorage.compressedJPEG(from: $0) }
            let newMachine = Machine(
                name: name,
                brand: brand.isEmpty ? nil : brand,
                model: modelName.isEmpty ? nil : modelName,
                notes: notes.isEmpty ? nil : notes,
                photoData: compressedPhoto,
                photoPath: nil,
                isActive: isActive,
                brandId: brandId
            )
            onSave(newMachine)
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

