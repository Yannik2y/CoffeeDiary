import SwiftUI
import UIKit

struct CameraCaptureView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIImagePickerController
    
    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraCaptureView
        
        init(parent: CameraCaptureView) {
            self.parent = parent
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onDismiss()
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            defer { parent.onDismiss() }
            guard let image = info[.originalImage] as? UIImage,
                  let data = image.jpegData(compressionQuality: 0.9) else { return }
            parent.onCapture(data)
        }
    }
    
    let onCapture: (Data) -> Void
    let onDismiss: () -> Void
    var onUnavailable: (() -> Void)? = nil
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            DispatchQueue.main.async {
                self.onUnavailable?()
                self.onDismiss()
            }
            return picker
        }
        
        picker.sourceType = .camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}
