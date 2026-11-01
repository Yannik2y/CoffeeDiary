import SwiftUI

/// Confirmation dialog shown when Save/Add would create a duplicate equipment name.
struct DuplicateNameSaveModifier: ViewModifier {
    @Binding var isPresented: Bool
    let onConfirmSave: () -> Void

    func body(content: Content) -> some View {
        content
            .confirmationDialog(
                "Duplicate name".localized,
                isPresented: $isPresented,
                titleVisibility: .visible
            ) {
                Button("Save Anyway".localized) {
                    onConfirmSave()
                }
                Button("Cancel".localized, role: .cancel) {}
            } message: {
                Text("An item with this name already exists. Save anyway?".localized)
            }
    }
}

extension View {
    func duplicateNameSaveConfirmation(
        isPresented: Binding<Bool>,
        onConfirmSave: @escaping () -> Void
    ) -> some View {
        modifier(
            DuplicateNameSaveModifier(
                isPresented: isPresented,
                onConfirmSave: onConfirmSave
            )
        )
    }
}

enum DuplicateNameSaveAction {
    /// Runs `save` immediately, or presents the duplicate confirmation when `hasDuplicate` is true.
    static func request(
        hasDuplicate: Bool,
        presentWarning: Binding<Bool>,
        save: @escaping () -> Void
    ) {
        if hasDuplicate {
            presentWarning.wrappedValue = true
        } else {
            save()
        }
    }
}
