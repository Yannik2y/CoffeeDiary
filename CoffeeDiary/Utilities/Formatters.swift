import Foundation

enum Formatters {
    static let number: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 1
        return f
    }()
    
    static func ratioString(dose: Double, yield: Double) -> String {
        guard dose > 0 else { return "—" }
        let ratio = yield / dose
        let parts = number.string(from: NSNumber(value: ratio)) ?? String(format: "%.1f", ratio)
        return "1:\(parts)"
    }
    
    static func secondsString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}


