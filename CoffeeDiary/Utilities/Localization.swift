import Foundation

/// Extension to make String localization easier
extension String {
    nonisolated var localized: String {
        return NSLocalizedString(self, comment: "")
    }

    nonisolated func localized(with arguments: CVarArg...) -> String {
        return String(format: NSLocalizedString(self, comment: ""), arguments: arguments)
    }
}
