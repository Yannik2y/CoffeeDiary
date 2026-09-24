import Foundation

enum ChartAnalyticsService {
    static let rollingWindow = 5
    static let espressoReferenceRatio = 2.0

    // MARK: - Filtering

    static func filter(
        _ brews: [ChartBrewRecord],
        options: ChartFilterOptions,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [ChartBrewRecord] {
        var result = brews

        if let days = options.timeRange.dayCount,
           let start = calendar.date(byAdding: .day, value: -days, to: now) {
            result = result.filter { $0.createdAt >= start }
        }

        if let style = options.brewStyle {
            result = result.filter { $0.brewStyle == style }
        }

        if let beanId = options.beanId {
            result = result.filter { $0.beanId == beanId }
        }

        if let coffeeName = options.coffeeNameFilter, !coffeeName.isEmpty {
            result = result.filter { $0.coffeeName == coffeeName }
        }

        return result.sorted { $0.createdAt < $1.createdAt }
    }

    static func previousPeriodBrews(
        _ brews: [ChartBrewRecord],
        options: ChartFilterOptions,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [ChartBrewRecord] {
        guard let days = options.timeRange.dayCount,
              let currentStart = calendar.date(byAdding: .day, value: -days, to: now),
              let previousStart = calendar.date(byAdding: .day, value: -days * 2, to: now) else {
            return []
        }

        var previousOptions = options
        previousOptions.timeRange = .all

        return filter(brews, options: previousOptions, now: now, calendar: calendar)
            .filter { $0.createdAt >= previousStart && $0.createdAt < currentStart }
    }

    static func beansWithBrews(in brews: [ChartBrewRecord]) -> [(id: UUID, name: String)] {
        var seen = Set<UUID>()
        var result: [(UUID, String)] = []
        for brew in brews.sorted(by: { ($0.beanName ?? "") < ($1.beanName ?? "") }) {
            guard let beanId = brew.beanId, let beanName = brew.beanName, !seen.contains(beanId) else { continue }
            seen.insert(beanId)
            result.append((beanId, beanName))
        }
        return result
    }

    // MARK: - KPIs

    static func buildKPIs(
        current: [ChartBrewRecord],
        previous: [ChartBrewRecord],
        styleFilter: BrewFlowType?
    ) -> [KPIStat] {
        // Ratio and time are style-scaled (~1:2 / ~25s espresso vs ~1:16 / ~3min filter).
        // When "All" is selected, keep those KPIs on espresso so averages stay meaningful.
        let ratioCurrent = brewsForRatioAndTime(current, styleFilter: styleFilter)
        let ratioPrevious = brewsForRatioAndTime(previous, styleFilter: styleFilter)

        return [
            KPIStat(
                id: "count",
                title: "Brew count".localized,
                value: "\(current.count)",
                delta: deltaString(current: Double(current.count), previous: Double(previous.count), suffix: "")
            ),
            KPIStat(
                id: "rating",
                title: "Avg rating".localized,
                value: formatOptional(averageRating(current), decimals: 1) ?? "—",
                delta: deltaOptional(
                    current: averageRating(current),
                    previous: averageRating(previous),
                    suffix: "",
                    decimals: 1
                )
            ),
            KPIStat(
                id: "ratio",
                title: "Avg ratio".localized,
                value: averageRatioLabel(ratioCurrent),
                delta: deltaOptional(
                    current: averageRatio(ratioCurrent),
                    previous: averageRatio(ratioPrevious),
                    suffix: "",
                    decimals: 1
                )
            ),
            KPIStat(
                id: "time",
                title: styleFilter == .filter ? "Avg brew time".localized : "Avg shot time".localized,
                value: formatOptional(averageBrewTime(ratioCurrent), decimals: 0).map { "\($0)s" } ?? "—",
                delta: deltaOptional(
                    current: averageBrewTime(ratioCurrent),
                    previous: averageBrewTime(ratioPrevious),
                    suffix: "s",
                    decimals: 0
                )
            )
        ]
    }

    /// Brews used for ratio / extraction-time style metrics.
    static func brewsForRatioAndTime(
        _ brews: [ChartBrewRecord],
        styleFilter: BrewFlowType?
    ) -> [ChartBrewRecord] {
        switch styleFilter {
        case .filter:
            return brews.filter { $0.brewStyle == .filter }
        case .espresso, .none:
            return brews.filter { $0.brewStyle == .espresso }
        }
    }

    static func averageRating(_ brews: [ChartBrewRecord]) -> Double? {
        let rated = brews.filter { $0.rating > 0 }
        guard !rated.isEmpty else { return nil }
        return Double(rated.map(\.rating).reduce(0, +)) / Double(rated.count)
    }

    static func averageRatio(_ brews: [ChartBrewRecord]) -> Double? {
        let valid = brews.filter { $0.doseGrams > 0 }
        guard !valid.isEmpty else { return nil }
        return valid.map(\.brewRatio).reduce(0, +) / Double(valid.count)
    }

    static func averageBrewTime(_ brews: [ChartBrewRecord]) -> Double? {
        let timed = brews.filter { $0.brewTimeSeconds > 0 }
        guard !timed.isEmpty else { return nil }
        return Double(timed.map(\.brewTimeSeconds).reduce(0, +)) / Double(timed.count)
    }

    // MARK: - Rolling average

    static func rollingAverage(_ points: [(date: Date, value: Double)], window: Int) -> [ChartPoint] {
        guard window > 1, points.count >= window else { return [] }
        var result: [ChartPoint] = []
        for index in (window - 1)..<points.count {
            let slice = points[(index - window + 1)...index]
            let avg = slice.map(\.value).reduce(0, +) / Double(slice.count)
            let point = points[index]
            result.append(
                ChartPoint(
                    brewId: UUID(),
                    date: point.date,
                    x: point.date.timeIntervalSince1970,
                    y: avg,
                    label: ""
                )
            )
        }
        return result
    }

    // MARK: - Trend

    static func linearTrend(_ points: [(x: Double, y: Double)]) -> ChartTrendLine? {
        guard points.count >= 2 else { return nil }
        let n = Double(points.count)
        let sumX = points.reduce(0) { $0 + $1.x }
        let sumY = points.reduce(0) { $0 + $1.y }
        let sumXY = points.reduce(0) { $0 + $1.x * $1.y }
        let sumX2 = points.reduce(0) { $0 + $1.x * $1.x }

        let denominator = n * sumX2 - sumX * sumX
        guard abs(denominator) > 1e-10 else { return nil }

        let slope = (n * sumXY - sumX * sumY) / denominator
        let intercept = (sumY - slope * sumX) / n

        let meanY = sumY / n
        let ssTot = points.reduce(0) { $0 + pow($1.y - meanY, 2) }
        let ssRes = points.reduce(0) { partial, p in
            let predicted = slope * p.x + intercept
            return partial + pow(p.y - predicted, 2)
        }
        let r2 = ssTot > 1e-10 ? max(0, 1 - ssRes / ssTot) : 0

        let xs = points.map(\.x)
        guard let minX = xs.min(), let maxX = xs.max() else { return nil }

        return ChartTrendLine(
            start: (x: minX, y: slope * minX + intercept),
            end: (x: maxX, y: slope * maxX + intercept),
            r2: r2
        )
    }

    // MARK: - Group breakdowns

    static func topRatedGroups(_ brews: [ChartBrewRecord], minCount: Int = 3, limit: Int = 5) -> [DimensionBreakdown] {
        var groups: [String: (name: String, beanId: UUID?, ratings: [Int], coffeeName: String?)] = [:]

        for brew in brews where brew.rating > 0 {
            let key: String
            let displayName: String
            let beanId: UUID?
            if let id = brew.beanId, let name = brew.beanName {
                key = id.uuidString
                displayName = name
                beanId = id
            } else {
                key = "coffee:\(brew.coffeeName)"
                displayName = brew.coffeeName
                beanId = nil
            }
            var entry = groups[key] ?? (displayName, beanId, [], brew.coffeeName)
            entry.ratings.append(brew.rating)
            groups[key] = entry
        }

        return groups.values
            .filter { $0.ratings.count >= minCount }
            .map { item in
                let avg = Double(item.ratings.reduce(0, +)) / Double(item.ratings.count)
                return DimensionBreakdown(
                    id: item.beanId?.uuidString ?? item.name,
                    name: item.name,
                    averageRating: avg,
                    count: item.ratings.count,
                    beanId: item.beanId,
                    coffeeName: item.coffeeName
                )
            }
            .sorted { lhs, rhs in
                if lhs.averageRating == rhs.averageRating {
                    return lhs.count > rhs.count
                }
                return lhs.averageRating > rhs.averageRating
            }
            .prefix(limit)
            .map { $0 }
    }

    static func shotTimeBuckets(_ brews: [ChartBrewRecord], bucketSize: Int = 5) -> [ShotTimeBucket] {
        var counts: [String: Int] = [:]
        for brew in brews where brew.brewTimeSeconds > 0 {
            let bucket = (brew.brewTimeSeconds / bucketSize) * bucketSize
            let key = "\(brew.shotType.rawValue)-\(bucket)"
            counts[key, default: 0] += 1
        }

        return counts.compactMap { key, count in
            let parts = key.split(separator: "-")
            guard parts.count == 2,
                  let shotRaw = Int(parts[0]),
                  let bucket = Int(parts[1]),
                  let shot = ShotType(rawValue: shotRaw) else { return nil }
            return ShotTimeBucket(
                id: key,
                bucketStart: bucket,
                shotType: shot,
                count: count
            )
        }
        .sorted { $0.bucketStart < $1.bucketStart }
    }

    static func weeklyRatingBuckets(_ brews: [ChartBrewRecord], calendar: Calendar = .current) -> [WeeklyRatingBucket] {
        var groups: [Date: [Int]] = [:]
        for brew in brews where brew.rating > 0 {
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: brew.createdAt)
            guard let weekStart = calendar.date(from: components) else { continue }
            groups[weekStart, default: []].append(brew.rating)
        }

        return groups.map { weekStart, ratings in
            let avg = Double(ratings.reduce(0, +)) / Double(ratings.count)
            return WeeklyRatingBucket(
                id: weekStart,
                weekStart: weekStart,
                averageRating: avg,
                count: ratings.count
            )
        }
        .sorted { $0.weekStart < $1.weekStart }
    }

    static func topBrews(_ brews: [ChartBrewRecord], limit: Int = 5) -> [TopBrewRow] {
        brews
            .filter { $0.rating > 0 }
            .sorted { lhs, rhs in
                if lhs.rating == rhs.rating {
                    return lhs.createdAt > rhs.createdAt
                }
                return lhs.rating > rhs.rating
            }
            .prefix(limit)
            .map { brew in
                TopBrewRow(
                    id: brew.id,
                    coffeeName: brew.coffeeName,
                    rating: brew.rating,
                    ratioLabel: Formatters.ratioString(dose: brew.doseGrams, yield: brew.yieldGrams),
                    date: brew.createdAt
                )
            }
    }

    // MARK: - Dashboard

    static func buildDashboard(
        from allBrews: [ChartBrewRecord],
        options: ChartFilterOptions,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> ChartsDashboardSnapshot {
        let filtered = filter(allBrews, options: options, now: now, calendar: calendar)
        let previous = previousPeriodBrews(allBrews, options: options, now: now, calendar: calendar)
        let espresso = filtered.filter { $0.brewStyle == .espresso }
        let filterStyle = filtered.filter { $0.brewStyle == .filter }

        // Ratio stability mixes poorly across styles (espresso ~1:2 vs filter ~1:16).
        // When filter is "All", plot espresso only — same scale as the 1:2 reference line.
        let ratioBrews = brewsForRatioAndTime(filtered, styleFilter: options.brewStyle)
        let extractionBrews = brewsForRatioAndTime(filtered, styleFilter: options.brewStyle)

        let ratioPoints = ratioBrews
            .filter { $0.doseGrams > 0 }
            .map { brew in
                ChartPoint(
                    brewId: brew.id,
                    date: brew.createdAt,
                    x: brew.createdAt.timeIntervalSince1970,
                    y: brew.brewRatio,
                    label: brew.coffeeName
                )
            }

        let ratioRolling = rollingAverage(
            ratioPoints.compactMap { point -> (date: Date, value: Double)? in
                guard let date = point.date else { return nil }
                return (date, point.y)
            },
            window: rollingWindow
        )

        let grindPoints = espresso
            .filter { $0.doseGrams > 0 }
            .map { brew in
                ChartPoint(
                    brewId: brew.id,
                    date: brew.createdAt,
                    x: brew.grinderSetting,
                    y: brew.brewRatio,
                    label: brew.coffeeName
                )
            }

        let extractionPoints = extractionBrews
            .filter { $0.brewTimeSeconds > 0 }
            .map { brew in
                ChartPoint(
                    brewId: brew.id,
                    date: brew.createdAt,
                    x: brew.createdAt.timeIntervalSince1970,
                    y: Double(brew.brewTimeSeconds),
                    label: brew.coffeeName
                )
            }

        let extractionRolling = rollingAverage(
            extractionPoints.compactMap { point -> (date: Date, value: Double)? in
                guard let date = point.date else { return nil }
                return (date, point.y)
            },
            window: rollingWindow
        )

        let waterTempPoints = filterStyle
            .filter { $0.waterTemperatureCelsius > 0 && $0.rating > 0 }
            .map { brew in
                ChartPoint(
                    brewId: brew.id,
                    date: brew.createdAt,
                    x: brew.waterTemperatureCelsius,
                    y: Double(brew.rating),
                    label: brew.coffeeName
                )
            }

        let weatherPoints = filtered
            .compactMap { brew -> ChartPoint? in
                guard let temp = brew.weatherTemperatureCelsius, brew.rating > 0 else { return nil }
                return ChartPoint(
                    brewId: brew.id,
                    date: brew.createdAt,
                    x: temp,
                    y: Double(brew.rating),
                    label: brew.coffeeName
                )
            }

        let weatherTrend = linearTrend(weatherPoints.map { (x: $0.x, y: $0.y) })

        let shotBuckets = shotTimeBuckets(espresso)
        let weeklyRatings = weeklyRatingBuckets(filtered, calendar: calendar)

        return ChartsDashboardSnapshot(
            kpis: buildKPIs(current: filtered, previous: previous, styleFilter: options.brewStyle),
            espressoTimedBrewCount: espresso.filter { $0.brewTimeSeconds > 0 }.count,
            ratioOverTime: ChartSeries(
                id: "ratioOverTime",
                title: "Ratio stability over time".localized,
                insight: ratioInsight(ratioBrews),
                points: ratioPoints,
                rollingAverage: ratioRolling,
                trendLine: nil,
                referenceY: options.brewStyle != .filter ? espressoReferenceRatio : nil,
                minimumSamples: 2
            ),
            grindVsRatio: ChartSeries(
                id: "grindVsRatio",
                title: "Grind setting vs ratio".localized,
                insight: grindInsight(espresso),
                points: grindPoints,
                rollingAverage: [],
                trendLine: linearTrend(grindPoints.map { (x: $0.x, y: $0.y) }),
                referenceY: nil,
                minimumSamples: 3
            ),
            shotTimeBuckets: shotBuckets,
            weeklyRatings: weeklyRatings,
            waterTempVsRating: ChartSeries(
                id: "waterTempVsRating",
                title: "Water temp vs rating".localized,
                insight: waterTempInsight(filterStyle),
                points: waterTempPoints,
                rollingAverage: [],
                trendLine: linearTrend(waterTempPoints.map { (x: $0.x, y: $0.y) }),
                referenceY: nil,
                minimumSamples: 3
            ),
            extractionTimeOverTime: ChartSeries(
                id: "extractionTime",
                title: "Extraction time over time".localized,
                insight: extractionInsight(extractionBrews),
                points: extractionPoints,
                rollingAverage: extractionRolling,
                trendLine: nil,
                referenceY: nil,
                minimumSamples: 2
            ),
            topCoffees: topRatedGroups(filtered),
            weatherVsRating: ChartSeries(
                id: "weatherVsRating",
                title: "Weather vs rating".localized,
                insight: weatherInsight(weatherPoints.count),
                points: weatherPoints,
                rollingAverage: [],
                trendLine: weatherTrend,
                referenceY: nil,
                minimumSamples: 5
            ),
            topBrews: topBrews(filtered),
            shotTimeInsight: shotTimeInsight(espresso, buckets: shotBuckets),
            weeklyRatingInsight: weeklyRatingInsight(weeklyRatings)
        )
    }

    // MARK: - Insight helpers

    private static func ratioInsight(_ brews: [ChartBrewRecord]) -> String {
        guard let avg = averageRatio(brews) else {
            return "Log doses and yields to track ratio stability.".localized
        }
        let label = Formatters.ratioString(dose: 1, yield: avg)
        return "Avg ratio %@ in this period.".localized(with: label)
    }

    private static func grindInsight(_ brews: [ChartBrewRecord]) -> String {
        guard brews.count >= 3 else {
            return "Need at least 3 espresso brews.".localized
        }
        return "See how grind changes affect your ratio.".localized
    }

    private static func waterTempInsight(_ brews: [ChartBrewRecord]) -> String {
        let valid = brews.filter { $0.waterTemperatureCelsius > 0 && $0.rating > 0 }
        guard valid.count >= 3 else {
            return "Need at least 3 rated filter brews with water temp.".localized
        }
        return "Explore whether temperature correlates with taste.".localized
    }

    private static func extractionInsight(_ brews: [ChartBrewRecord]) -> String {
        guard let avg = averageBrewTime(brews) else {
            return "Record brew time to spot consistency trends.".localized
        }
        return "Avg time %@ in this period.".localized(with: Formatters.secondsString(Int(avg.rounded())))
    }

    private static func weatherInsight(_ count: Int) -> String {
        if count < 5 {
            return "Need at least 5 weather-tagged rated brews.".localized
        }
        return "Outdoor air temp vs rating · %d brews".localized(with: count)
    }

    private static func shotTimeInsight(_ brews: [ChartBrewRecord], buckets: [ShotTimeBucket]) -> String {
        guard !buckets.isEmpty else {
            return "Record shot times to see consistency.".localized
        }
        let dominant = buckets.max(by: { $0.count < $1.count })
        if let dominant {
            return "Most shots land around %ds.".localized(with: dominant.bucketStart)
        }
        return ""
    }

    private static func weeklyRatingInsight(_ buckets: [WeeklyRatingBucket]) -> String {
        guard let latest = buckets.last, latest.count >= 3 else {
            return "Rate more brews each week for reliable averages.".localized
        }
        return "Latest week avg: %.1f stars (%d brews).".localized(with: latest.averageRating, latest.count)
    }

    private static func averageRatioLabel(_ brews: [ChartBrewRecord]) -> String {
        guard let avg = averageRatio(brews) else { return "—" }
        return Formatters.ratioString(dose: 1, yield: avg)
    }

    private static func formatOptional(_ value: Double?, decimals: Int) -> String? {
        guard let value else { return nil }
        return String(format: "%.\(decimals)f", value)
    }

    private static func deltaString(current: Double, previous: Double, suffix: String) -> String? {
        guard previous > 0 || current > 0 else { return nil }
        let diff = current - previous
        if abs(diff) < 0.05 { return "vs prior period".localized }
        let arrow = diff > 0 ? "↑" : "↓"
        let formatted = String(format: "%.1f", abs(diff))
        return "\(arrow) \(formatted)\(suffix) \("vs prior period".localized)"
    }

    private static func deltaOptional(
        current: Double?,
        previous: Double?,
        suffix: String,
        decimals: Int
    ) -> String? {
        guard let current, let previous else { return nil }
        return deltaString(current: current, previous: previous, suffix: suffix)
    }
}
