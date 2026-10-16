import AVFoundation
import UIKit

/// Presents `UIImagePickerController` via UIKit from the topmost view controller.
/// Embedding the camera picker in a SwiftUI `fullScreenCover` inside a `Form` sheet
/// is a known crash source; presenting it natively avoids that path.
@MainActor
enum CameraCapturePresenter {
    private static var activeDelegate: PickerDelegate?

    static func present(
        onCapture: @escaping (Data) -> Void,
        onDismiss: @escaping () -> Void = {},
        onUnavailable: @escaping () -> Void = {}
    ) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            onUnavailable()
            return
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            presentPicker(onCapture: onCapture, onDismiss: onDismiss, onUnavailable: onUnavailable)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                Task { @MainActor in
                    if granted {
                        presentPicker(onCapture: onCapture, onDismiss: onDismiss, onUnavailable: onUnavailable)
                    } else {
                        onUnavailable()
                    }
                }
            }
        case .denied, .restricted:
            onUnavailable()
        @unknown default:
            onUnavailable()
        }
    }

    private static func presentPicker(
        onCapture: @escaping (Data) -> Void,
        onDismiss: @escaping () -> Void,
        onUnavailable: @escaping () -> Void
    ) {
        guard let presenter = UIApplication.shared.coffeeDiaryTopViewController() else {
            onUnavailable()
            return
        }

        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = false
        picker.modalPresentationStyle = .fullScreen

        let delegate = PickerDelegate(
            onCapture: onCapture,
            onFinish: {
                activeDelegate = nil
                onDismiss()
            }
        )
        activeDelegate = delegate
        picker.delegate = delegate
        presenter.present(picker, animated: true)
    }

    private final class PickerDelegate: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let onCapture: (Data) -> Void
        private let onFinish: () -> Void

        init(onCapture: @escaping (Data) -> Void, onFinish: @escaping () -> Void) {
            self.onCapture = onCapture
            self.onFinish = onFinish
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true) { [onFinish] in
                onFinish()
            }
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let image = info[.originalImage] as? UIImage
            let data = image?.jpegData(compressionQuality: 0.9)
            picker.dismiss(animated: true) { [onCapture, onFinish] in
                if let data {
                    onCapture(data)
                }
                onFinish()
            }
        }
    }
}

private extension UIApplication {
    func coffeeDiaryTopViewController(base: UIViewController? = nil) -> UIViewController? {
        let root = base ?? connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController

        if let navigation = root as? UINavigationController {
            return coffeeDiaryTopViewController(base: navigation.visibleViewController)
        }
        if let tab = root as? UITabBarController {
            return coffeeDiaryTopViewController(base: tab.selectedViewController)
        }
        if let presented = root?.presentedViewController {
            return coffeeDiaryTopViewController(base: presented)
        }
        return root
    }
}
