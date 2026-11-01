import SwiftUI

/// Outer-display (cover) UI shown to the subject while capturing on the inner display.
struct DuoCameraSubjectPrompt: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.white)
                Text("Hold still".localized)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                Text("Capturing your gear photo…".localized)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Hold still. Capturing your gear photo.".localized)
    }
}

extension View {
    /// Registers a Duo cover-display accessory while a camera session is active.
    /// No-op unless compiled with `ENABLE_DUO_APIS` (Xcode 27.1+).
    func duoCameraCaptureAccessory(isEnabled: Binding<Bool>) -> some View {
        #if ENABLE_DUO_APIS
        modifier(DuoCameraCaptureAccessoryModifier(isEnabled: isEnabled))
        #else
        self
        #endif
    }
}

#if ENABLE_DUO_APIS

@available(iOS 27.1, *)
private struct DuoCameraCaptureAccessoryModifier: ViewModifier {
    @Binding var isEnabled: Bool
    @State private var isAvailable = false

    func body(content: Content) -> some View {
        content
            .sceneAccessory {
                CameraCaptureAccessory(isEnabled: $isEnabled) {
                    DuoCameraSubjectPrompt()
                }
                .onAvailabilityChange { available in
                    isAvailable = available
                    if !available {
                        isEnabled = false
                    }
                }
            }
    }
}

#endif
