import Foundation

enum BrewFlowType: String, CaseIterable, Identifiable, Codable, Sendable {
    case espresso
    case filter

    var id: String { rawValue }

    var title: String {
        switch self {
        case .espresso: return "Espresso".localized
        case .filter: return "Filter".localized
        }
    }
}

enum PickerSelection {
    static let none = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
}
