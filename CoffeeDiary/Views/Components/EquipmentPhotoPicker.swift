import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import UIKit

struct EquipmentPhotoPicker: View {
    @Binding var photoData: Data?
    @Binding var attachmentError: String?

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showingDocumentPicker = false
    @State private var showingCamera = false

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

            if cameraAvailable {
                Button { showingCamera = true } label: {
                    Label("Take Photo".localized, systemImage: "camera")
                }
            }

            Button { showingDocumentPicker = true } label: {
                Label("Import Image".localized, systemImage: "photo")
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
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await MainActor.run { handleAttachmentData(data) }
                }
            }
        }
        .fileImporter(isPresented: $showingDocumentPicker, allowedContentTypes: [.image]) { result in
            if case .success(let url) = result {
                let accessing = url.startAccessingSecurityScopedResource()
                defer { if accessing { url.stopAccessingSecurityScopedResource() } }
                if let data = try? Data(contentsOf: url) {
                    handleAttachmentData(data)
                }
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraCaptureView(onCapture: { data in
                handleAttachmentData(data)
                showingCamera = false
            }, onDismiss: { showingCamera = false })
        }
    }

    private func handleAttachmentData(_ data: Data) {
        if data.count > attachmentLimitBytes {
            attachmentError = "Files must be smaller than 8 MB.".localized
            return
        }
        // Reject non-image payloads early (e.g. mislabeled files) so saves don't silently drop them.
        guard UIImage(data: data) != nil else {
            attachmentError = "Only image files are supported.".localized
            return
        }
        attachmentError = nil
        photoData = data
    }
}
