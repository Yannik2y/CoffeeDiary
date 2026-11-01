import Foundation

/// Case- and diacritic-insensitive name matching for equipment duplicate warnings.
enum EquipmentDuplicateName {
    static func normalized(_ name: String) -> String {
        name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    /// Returns true when `candidate` matches another item's name, excluding `excludingId` (edit case).
    static func hasDuplicate(
        candidate: String,
        existing: [(id: UUID, name: String)],
        excludingId: UUID? = nil
    ) -> Bool {
        let key = normalized(candidate)
        guard !key.isEmpty else { return false }
        return existing.contains { item in
            if let excludingId, item.id == excludingId { return false }
            return normalized(item.name) == key
        }
    }
}
