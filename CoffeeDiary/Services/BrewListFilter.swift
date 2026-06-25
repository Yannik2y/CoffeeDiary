import Foundation

struct BrewFilterCriteria: Equatable {
    var searchText: String = ""
    var shotType: ShotType?
    var brewStyle: BrewFlowType?
    var startDate: Date?
    var endDate: Date?
    var minRatio: Double?
    var maxRatio: Double?
    var minRating: Int?

    var hashValue: Int {
        var hasher = Hasher()
        hasher.combine(searchText)
        hasher.combine(shotType?.rawValue ?? -1)
        hasher.combine(brewStyle?.rawValue ?? "all")
        hasher.combine(startDate?.timeIntervalSince1970 ?? 0)
        hasher.combine(endDate?.timeIntervalSince1970 ?? 0)
        hasher.combine(minRatio ?? -1)
        hasher.combine(maxRatio ?? -1)
        hasher.combine(minRating ?? 0)
        return hasher.finalize()
    }

    var hasActiveFilters: Bool {
        shotType != nil ||
        brewStyle != nil ||
        startDate != nil ||
        endDate != nil ||
        (minRatio ?? 0) > 0 ||
        (maxRatio ?? 0) > 0 ||
        (minRating ?? 0) > 0
    }
}

enum BrewListFilter {
    static func apply(_ criteria: BrewFilterCriteria, to brews: [BrewEntry]) -> [BrewEntry] {
        brews.filter { entry in
            var ok = true
            if let shot = criteria.shotType {
                ok = ok && entry.shotType == shot
            }
            if let style = criteria.brewStyle {
                ok = ok && entry.brewStyle == style
            }
            let search = criteria.searchText
            if !search.isEmpty {
                if entry.coffeeName.lowercased().contains(search) {
                    // match
                } else {
                    let haystack = [
                        entry.notes ?? "",
                        entry.bean?.name ?? "",
                        entry.bean?.roaster ?? ""
                    ].joined(separator: " ").lowercased()
                    ok = ok && haystack.contains(search)
                }
            }
            if let start = criteria.startDate {
                ok = ok && entry.createdAt >= Calendar.current.startOfDay(for: start)
            }
            if let end = criteria.endDate {
                let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: end) ?? end
                ok = ok && entry.createdAt <= endOfDay
            }
            let ratio = entry.brewRatio
            if let minR = criteria.minRatio, minR > 0 {
                ok = ok && ratio >= minR
            }
            if let maxR = criteria.maxRatio, maxR > 0 {
                ok = ok && ratio <= maxR
            }
            if let minRating = criteria.minRating, minRating > 0 {
                ok = ok && entry.rating >= minRating
            }
            return ok
        }
    }
}
