import Foundation

enum Formatters {
    nonisolated static func ratioString(dose: Double, yield: Double) -> String {
        guard dose > 0 else { return "—" }
        let ratio = yield / dose
        // Local formatter: NumberFormatter is not thread-safe to share across actors.
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        let parts = formatter.string(from: NSNumber(value: ratio)) ?? String(format: "%.1f", ratio)
        return "1:\(parts)"
    }

    /// Shared formatter for UI text fields on the main actor only.
    static let number: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 1
        return f
    }()

    nonisolated static func secondsString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
