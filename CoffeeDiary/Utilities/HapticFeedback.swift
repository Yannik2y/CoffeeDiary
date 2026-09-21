import UIKit

enum HapticFeedback {
    private static let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let notificationGenerator = UINotificationFeedbackGenerator()
    private static let selectionGenerator = UISelectionFeedbackGenerator()

    static func light() {
        lightGenerator.prepare()
        lightGenerator.impactOccurred()
    }

    static func success() {
        notificationGenerator.prepare()
        notificationGenerator.notificationOccurred(.success)
    }

    static func selection() {
        selectionGenerator.prepare()
        selectionGenerator.selectionChanged()
    }
}
