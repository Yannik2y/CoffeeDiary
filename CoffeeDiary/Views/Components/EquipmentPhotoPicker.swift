import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import UIKit

struct EquipmentPhotoPicker: View {
    @Binding var photoData: Data?
    @Binding var attachmentError: String?

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showingDocumentPicker = false
    @State private var isProcessingAttachment = false

    private let attachmentLimitBytes = 8 * 1024 * 1024
    private var cameraAvailable: Bool { UIImagePickerController.isSourceTypeAvailable(.camera) }

    var body: some View {
        Section("Photo".localized) {
            if let photoData, let image = UIImage(data: photoData) {
                VStack(spacing: 8) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    Button("Remove Photo".localized, role: .destructive) {
                        self.photoData = nil
                    }
                }
            }

            PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()) {
                Label(photoData == nil ? "Add Photo".localized : "Replace Photo".localized, systemImage: "photo.on.rectangle")
            }
            .disabled(isProcessingAttachment)

            if cameraAvailable {
                Button {
                    presentCamera()
                } label: {
                    Label("Take Photo".localized, systemImage: "camera")
                }
                .disabled(isProcessingAttachment)
            }

            Button { showingDocumentPicker = true } label: {
                Label("Import Image".localized, systemImage: "photo")
            }
            .disabled(isProcessingAttachment)

            if isProcessingAttachment {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let attachmentError {
                Text(attachmentError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .onChange(of: selectedPhoto) { _, item in
            guard let item else { return }
            Task {
                do {
                    guard let data = try await item.loadTransferable(type: Data.self) else {
                        await MainActor.run {
                            attachmentError = "Couldn't load the selected photo.".localized
                        }
                        return
                    }
                    await handleAttachmentData(data)
                } catch {
                    await MainActor.run {
                        attachmentError = "Couldn't load the selected photo.".localized
                    }
                }
            }
        }
        .fileImporter(isPresented: $showingDocumentPicker, allowedContentTypes: [.image]) { result in
            switch result {
            case .success(let url):
                Task {
                    let accessing = url.startAccessingSecurityScopedResource()
                    defer { if accessing { url.stopAccessingSecurityScopedResource() } }
                    do {
                        let data = try Data(contentsOf: url)
                        await handleAttachmentData(data)
                    } catch {
                        await MainActor.run {
                            attachmentError = "Couldn't load the selected photo.".localized
                        }
                    }
                }
            case .failure:
                attachmentError = "Couldn't load the selected photo.".localized
            }
        }
    }

    private func presentCamera() {
        // Present on the next run loop so the Form row finishes its own interaction
        // before UIKit presents the camera (avoids nested presentation races).
        DispatchQueue.main.async {
            CameraCapturePresenter.present(
                onCapture: { data in
                    Task { await handleAttachmentData(data) }
                },
                onUnavailable: {
                    attachmentError = "Camera is not available.".localized
                }
            )
        }
    }

    @MainActor
    private func handleAttachmentData(_ data: Data) async {
        if data.count > attachmentLimitBytes {
            attachmentError = "Files must be smaller than 8 MB.".localized
            return
        }
        isProcessingAttachment = true
        defer { isProcessingAttachment = false }

        // Compress off the main actor so forms never keep multi‑MB camera originals.
        guard let compressed = await PhotoStorage.compressedJPEGAsync(from: data) else {
            attachmentError = "Only image files are supported.".localized
            return
        }
        attachmentError = nil
        photoData = compressed
    }
}
