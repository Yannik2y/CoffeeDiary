import Foundation

struct DialInSuggestion: Equatable {
    let message: String
    let suggestedDose: Double?
    let suggestedYield: Double?
    let suggestedTime: Int?
}

enum DialInAssistant {
    static func suggestion(for bean: Bean?, in brews: [BrewEntry]) -> DialInSuggestion? {
        guard let bean else { return nil }
        let related = brews
            .filter { $0.bean?.id == bean.id && $0.brewStyle == .espresso }
            .prefix(5)
        guard related.count >= 3 else { return nil }

        let rated = related.filter { $0.rating > 0 }
        guard rated.count >= 2 else { return nil }

        let avgRating = Double(rated.map(\.rating).reduce(0, +)) / Double(rated.count)
        guard let best = rated.max(by: { $0.rating < $1.rating }),
              let latest = related.first else { return nil }

        if avgRating < 3 && latest.rating <= 3 {
            return DialInSuggestion(
                message: "Try adjusting yield ±1g or grind finer based on your last %d shots.".localized(with: related.count),
                suggestedDose: best.doseGrams,
                suggestedYield: best.yieldGrams + 1,
                suggestedTime: best.brewTimeSeconds
            )
        }
        if latest.rating >= 4 {
            return DialInSuggestion(
                message: "Great dial-in! Your last shot scored %d stars — consider saving this as a reference.".localized(with: latest.rating),
                suggestedDose: latest.doseGrams,
                suggestedYield: latest.yieldGrams,
                suggestedTime: latest.brewTimeSeconds
            )
        }
        return nil
    }
}
