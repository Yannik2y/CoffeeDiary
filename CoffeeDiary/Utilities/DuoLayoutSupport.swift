import SwiftUI

/// High-level hinge posture used across the app. Independent of the iOS 27.1 SDK so
/// older toolchains (CI / Xcode 16) still compile; live updates arrive only when
/// `ENABLE_DUO_APIS` is set while building with Xcode 27.1+.
enum DuoHingeStatus: Equatable, Sendable {
    case unknown
    case closed
    case partiallyOpen
    case fullyOpen
}

struct DuoHingeState: Equatable, Sendable {
    var status: DuoHingeStatus = .unknown
    /// Degrees when known; `nil` on non-Duo / without Duo APIs.
    var angleDegrees: Double?

    var prefersWideLayout: Bool {
        switch status {
        case .fullyOpen: true
        case .partiallyOpen, .closed, .unknown: false
        }
    }
}

private struct DuoHingeStateKey: EnvironmentKey {
    static let defaultValue = DuoHingeState()
}

extension EnvironmentValues {
    var duoHingeState: DuoHingeState {
        get { self[DuoHingeStateKey.self] }
        set { self[DuoHingeStateKey.self] = newValue }
    }
}

extension View {
    /// Tracks hinge posture when Duo APIs are compiled in; otherwise a no-op.
    func observeDuoHinge() -> some View {
        modifier(DuoHingeObserverModifier())
    }

    /// Keeps bottom chrome clear of an active fold division when Duo APIs are available.
    func duoFoldSafeBottomInset(extra: CGFloat = 0) -> some View {
        modifier(DuoFoldSafeBottomInsetModifier(extra: extra))
    }

    /// Slightly denser horizontal padding when the hinge reports fully open.
    func duoWideContentPadding() -> some View {
        modifier(DuoWideContentPaddingModifier())
    }
}

// MARK: - Always-compiling modifiers (real work behind ENABLE_DUO_APIS)

private struct DuoHingeObserverModifier: ViewModifier {
    @State private var hingeState = DuoHingeState()

    func body(content: Content) -> some View {
        content
            .environment(\.duoHingeState, hingeState)
            #if ENABLE_DUO_APIS
            .modifier(DuoHingeTrackingModifier(hingeState: $hingeState))
            #endif
    }
}

private struct DuoFoldSafeBottomInsetModifier: ViewModifier {
    let extra: CGFloat

    func body(content: Content) -> some View {
        #if ENABLE_DUO_APIS
        content.modifier(DuoFoldSafeBottomInsetAPIsModifier(extra: extra))
        #else
        content
        #endif
    }
}

private struct DuoWideContentPaddingModifier: ViewModifier {
    @Environment(\.duoHingeState) private var hinge
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    func body(content: Content) -> some View {
        let wide = hinge.prefersWideLayout || horizontalSizeClass == .regular
        content.padding(.horizontal, wide ? 8 : 0)
    }
}

#if ENABLE_DUO_APIS

@available(iOS 27.1, *)
private struct DuoHingeTrackingModifier: ViewModifier {
    @Binding var hingeState: DuoHingeState

    func body(content: Content) -> some View {
        content.onHingeChange { _, newContext in
            guard let hinge = newContext.hinge else {
                hingeState = DuoHingeState(status: .unknown, angleDegrees: nil)
                return
            }
            let status: DuoHingeStatus
            switch hinge.status {
            case .closed: status = .closed
            case .partiallyOpen: status = .partiallyOpen
            case .fullyOpen: status = .fullyOpen
            @unknown default: status = .unknown
            }
            hingeState = DuoHingeState(
                status: status,
                angleDegrees: hinge.angle.degrees
            )
        }
    }
}

@available(iOS 27.1, *)
private struct DuoFoldClearanceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

@available(iOS 27.1, *)
private struct DuoFoldSafeBottomInsetAPIsModifier: ViewModifier {
    let extra: CGFloat
    @State private var clearance: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .padding(.bottom, clearance + extra)
            .background {
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: DuoFoldClearanceKey.self,
                        value: Self.bottomClearance(proxy: proxy)
                    )
                }
            }
            .onPreferenceChange(DuoFoldClearanceKey.self) { clearance = $0 }
    }

    /// Extra bottom padding when a horizontal (tabletop) fold would collide with chrome.
    private static func bottomClearance(proxy: GeometryProxy) -> CGFloat {
        guard let division = proxy.reservedRegions(kind: .division).first else { return 0 }
        let frame = division.frame
        // Vertical book fold — bottom bar is fine full-width.
        guard frame.width >= frame.height else { return 0 }
        let lowerPaneHeight = proxy.size.height - frame.maxY
        // If the lower pane is too short for controls, push content above the crease.
        if lowerPaneHeight < 140 {
            return frame.height + division.margins.top + division.margins.bottom
        }
        return 0
    }
}

#endif
