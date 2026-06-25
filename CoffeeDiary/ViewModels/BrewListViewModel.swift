import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class BrewListViewModel {
    var cachedFilteredBrews: [BrewEntry] = []
    private var lastFilterHash: Int = 0

    func updateFilteredBrews(from allBrews: [BrewEntry], criteria: BrewFilterCriteria) {
        let currentHash = criteria.hashValue ^ allBrews.count
        guard currentHash != lastFilterHash else { return }
        lastFilterHash = currentHash
        cachedFilteredBrews = BrewListFilter.apply(criteria, to: allBrews)
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
