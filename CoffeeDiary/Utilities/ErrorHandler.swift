import SwiftUI
import SwiftData

/// Utility for handling SwiftData save operations with user-facing error messages.
/// Delegates to BrewStore so there is a single save + notification path.
enum ErrorHandler {
    /// Saves the model context and shows an error alert if the save fails
    @discardableResult
    static func save(
        _ modelContext: ModelContext,
        errorMessage: String? = nil,
        onSuccess: (() -> Void)? = nil
    ) -> Bool {
        let ok = BrewStore.shared.save(modelContext, errorMessage: errorMessage)
        if ok {
            onSuccess?()
        }
        return ok
    }

    /// Saves the model context asynchronously (still on MainActor via BrewStore).
    @MainActor
    @discardableResult
    static func saveAsync(
        _ modelContext: ModelContext,
        errorMessage: String? = nil,
        onSuccess: (() -> Void)? = nil
    ) async -> Bool {
        let ok = await BrewStore.shared.saveAsync(modelContext, errorMessage: errorMessage)
        if ok {
            onSuccess?()
        }
        return ok
    }
}

/// View modifier to show error alerts from ErrorHandler / BrewStore
struct ErrorAlertModifier: ViewModifier {
    @State private var errorMessage: String?
    @State private var showError = false

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .modelContextSaveError)) { notification in
                if let message = notification.userInfo?["message"] as? String {
                    errorMessage = message
                    showError = true
                }
            }
            .alert("Error".localized, isPresented: $showError) {
                Button("OK".localized, role: .cancel) { }
            } message: {
                if let errorMessage {
                    Text(errorMessage)
                }
            }
    }
}

extension View {
    /// Adds error alert handling to a view
    func errorAlert() -> some View {
        modifier(ErrorAlertModifier())
    }
}
