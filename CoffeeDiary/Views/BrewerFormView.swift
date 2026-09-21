import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers
import UIKit

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
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showingDocumentPicker = false
    @State private var showingCamera = false
    @State private var attachmentError: String?
    
    private let attachmentLimitBytes = 8 * 1024 * 1024
    private var cameraAvailable: Bool { UIImagePickerController.isSourceTypeAvailable(.camera) }
    
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
            .navigationTitle(isEditing ? "Edit Brewer" : "New Brewer")
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
        if let brewer {
            brewer.name = name
            brewer.brand = brand.isEmpty ? nil : brand
            brewer.style = style.isEmpty ? nil : style
            brewer.notes = notes.isEmpty ? nil : notes
            brewer.isFavorite = isFavorite
            brewer.photoData = photoData.flatMap { PhotoStorage.compressedJPEG(from: $0) }
            brewer.photoPath = nil
            onSave(brewer)
        } else {
            let compressedPhoto = photoData.flatMap { PhotoStorage.compressedJPEG(from: $0) }
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


