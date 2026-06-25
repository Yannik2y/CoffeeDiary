import SwiftUI
import SwiftData

/// Utility for handling SwiftData save operations with user-facing error messages
enum ErrorHandler {
    /// Saves the model context and shows an error alert if the save fails
    /// - Parameters:
    ///   - modelContext: The ModelContext to save
    ///   - errorMessage: Optional custom error message to show
    ///   - onSuccess: Optional closure to execute on successful save
    static func save(
        _ modelContext: ModelContext,
        errorMessage: String? = nil,
        onSuccess: (() -> Void)? = nil
    ) {
        do {
            try modelContext.save()
            onSuccess?()
        } catch {
            let message = errorMessage ?? "Failed to save changes. Please try again.".localized
            // Log error for debugging
            print("ModelContext save failed: \(error.localizedDescription)")
            
            // Show error alert on main thread
            DispatchQueue.main.async {
                // Note: In a real app, you might want to use a more sophisticated
                // error presentation system (e.g., a shared error state manager)
                // For now, we'll use a simple approach that can be enhanced later
                NotificationCenter.default.post(
                    name: NSNotification.Name("ModelContextSaveError"),
                    object: nil,
                    userInfo: ["message": message]
                )
            }
        }
    }
    
    /// Saves the model context asynchronously
    @MainActor
    static func saveAsync(
        _ modelContext: ModelContext,
        errorMessage: String? = nil,
        onSuccess: (() -> Void)? = nil
    ) async {
        do {
            try modelContext.save()
            onSuccess?()
        } catch {
            let message = errorMessage ?? "Failed to save changes. Please try again.".localized
            print("ModelContext save failed: \(error.localizedDescription)")
            
            NotificationCenter.default.post(
                name: NSNotification.Name("ModelContextSaveError"),
                object: nil,
                userInfo: ["message": message]
            )
        }
    }
}

/// View modifier to show error alerts from ErrorHandler
struct ErrorAlertModifier: ViewModifier {
    @State private var errorMessage: String?
    @State private var showError = false
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ModelContextSaveError"))) { notification in
                if let message = notification.userInfo?["message"] as? String {
                    errorMessage = message
                    showError = true
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
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

