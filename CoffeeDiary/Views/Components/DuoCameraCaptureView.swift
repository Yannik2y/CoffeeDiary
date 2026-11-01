import AVFoundation
import SwiftUI

#if ENABLE_DUO_APIS

/// Full-screen capture on the inner display with an optional cover-display prompt (Duo).
@available(iOS 27.1, *)
struct DuoCameraCaptureView: View {
    let onCapture: (Data) -> Void
    let onCancel: () -> Void

    @State private var session = DuoCaptureSession()
    @State private var accessoryEnabled = true
    @State private var accessoryAvailable = false
    @State private var isCapturing = false

    var body: some View {
        NavigationStack {
            ZStack {
                DuoCameraPreview(session: session.avSession)
                    .ignoresSafeArea()

                VStack {
                    Spacer()
                    Button {
                        Task { await takePhoto() }
                    } label: {
                        Circle()
                            .strokeBorder(.white, lineWidth: 4)
                            .background(Circle().fill(.white.opacity(0.25)))
                            .frame(width: 72, height: 72)
                    }
                    .disabled(isCapturing || session.state != .running)
                    .padding(.bottom, 32)
                    .accessibilityLabel("Take Photo".localized)
                }
            }
            .navigationTitle("Take Photo".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized, action: onCancel)
                }
            }
            .sceneAccessory {
                CameraCaptureAccessory(isEnabled: $accessoryEnabled) {
                    DuoCameraSubjectPrompt()
                }
                .onAvailabilityChange { available in
                    accessoryAvailable = available
                    if !available { accessoryEnabled = false }
                }
            }
            .task { await session.start() }
            .onDisappear { session.stop() }
        }
    }

    private func takePhoto() async {
        isCapturing = true
        defer { isCapturing = false }
        guard let data = await session.captureJPEG() else { return }
        onCapture(data)
    }
}

// MARK: - Session

@available(iOS 27.1, *)
@Observable
@MainActor
final class DuoCaptureSession {
    enum State { case idle, running, unavailable }

    private(set) var state: State = .idle
    let avSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "YC.CoffeeDiary.duoCapture")
    private let photoOutput = AVCapturePhotoOutput()
    private var photoDelegate: PhotoDelegate?

    func start() async {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        guard granted else {
            state = .unavailable
            return
        }
        let started = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            sessionQueue.async {
                let session = self.avSession
                session.beginConfiguration()
                defer { session.commitConfiguration() }

                if session.inputs.isEmpty,
                   let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
                    ?? AVCaptureDevice.default(for: .video),
                   let input = try? AVCaptureDeviceInput(device: device),
                   session.canAddInput(input) {
                    session.addInput(input)
                }
                if session.outputs.isEmpty, session.canAddOutput(self.photoOutput) {
                    session.addOutput(self.photoOutput)
                }
                session.startRunning()
                cont.resume(returning: session.isRunning)
            }
        }
        state = started ? .running : .unavailable
    }

    func stop() {
        sessionQueue.async { self.avSession.stopRunning() }
        state = .idle
    }

    func captureJPEG() async -> Data? {
        await withCheckedContinuation { cont in
            sessionQueue.async {
                let delegate = PhotoDelegate { data in
                    cont.resume(returning: data)
                }
                self.photoDelegate = delegate
                let settings = AVCapturePhotoSettings()
                self.photoOutput.capturePhoto(with: settings, delegate: delegate)
            }
        }
    }

    private final class PhotoDelegate: NSObject, AVCapturePhotoCaptureDelegate, @unchecked Sendable {
        private let completion: (Data?) -> Void

        init(completion: @escaping (Data?) -> Void) {
            self.completion = completion
        }

        func photoOutput(
            _ output: AVCapturePhotoOutput,
            didFinishProcessingPhoto photo: AVCapturePhoto,
            error: Error?
        ) {
            if error != nil {
                completion(nil)
                return
            }
            completion(photo.fileDataRepresentation())
        }
    }
}

@available(iOS 27.1, *)
private struct DuoCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.previewLayer.session = session
    }

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}

#endif

enum DuoCameraCapturePresenter {
    /// `true` when this build includes Duo APIs and the OS is new enough to present them.
    @MainActor
    static var isAvailable: Bool {
        #if ENABLE_DUO_APIS
        if #available(iOS 27.1, *) { return true }
        #endif
        return false
    }
}
