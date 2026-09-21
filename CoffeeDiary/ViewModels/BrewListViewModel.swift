import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class BrewListViewModel {
    var cachedFilteredBrews: [BrewEntry] = []
    private var lastFilterHash: Int = 0
    private var lastContentFingerprint: Int = 0

    func updateFilteredBrews(from allBrews: [BrewEntry], criteria: BrewFilterCriteria) {
        let contentFingerprint = Self.contentFingerprint(for: allBrews)
        let currentHash = criteria.hashValue
        guard currentHash != lastFilterHash || contentFingerprint != lastContentFingerprint else { return }
        lastFilterHash = currentHash
        lastContentFingerprint = contentFingerprint
        cachedFilteredBrews = BrewListFilter.apply(criteria, to: allBrews)
    }

    /// Fingerprint that changes when brew content (not just count) changes.
    static func contentFingerprint(for brews: [BrewEntry]) -> Int {
        var hasher = Hasher()
        hasher.combine(brews.count)
        for brew in brews {
            hasher.combine(brew.id)
            hasher.combine(brew.coffeeName)
            hasher.combine(brew.rating)
            hasher.combine(brew.isFavorite)
            hasher.combine(brew.doseGrams)
            hasher.combine(brew.yieldGrams)
            hasher.combine(brew.brewTimeSeconds)
            hasher.combine(brew.createdAt.timeIntervalSince1970)
            hasher.combine(brew.notes ?? "")
            hasher.combine(brew.bean?.id)
        }
        return hasher.finalize()
    }

    static func fetchPredicateFiltered(
        context: ModelContext,
        brewStyle: BrewFlowType?,
        minRating: Int?
    ) -> [BrewEntry]? {
        guard brewStyle != nil || (minRating ?? 0) > 0 else { return nil }
        let descriptor: FetchDescriptor<BrewEntry>
        if let style = brewStyle, let minRating, minRating > 0 {
            let raw = style.rawValue
            descriptor = FetchDescriptor<BrewEntry>(
                predicate: #Predicate { $0.brewStyleRaw == raw && $0.rating >= minRating },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
        } else if let style = brewStyle {
            let raw = style.rawValue
            descriptor = FetchDescriptor<BrewEntry>(
                predicate: #Predicate { $0.brewStyleRaw == raw },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
        } else if let minRating, minRating > 0 {
            descriptor = FetchDescriptor<BrewEntry>(
                predicate: #Predicate { $0.rating >= minRating },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
        } else {
            return nil
        }
        return try? context.fetch(descriptor)
    }
}
