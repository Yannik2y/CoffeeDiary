import Foundation
import Observation

@Observable
@MainActor
final class ChartsViewModel {
    var filterOptions = ChartFilterOptions()
    private(set) var dashboard = ChartsDashboardSnapshot(
        kpis: [],
        espressoTimedBrewCount: 0,
        ratioOverTime: .empty(id: "ratioOverTime", title: "Ratio stability over time".localized),
        grindVsRatio: .empty(id: "grindVsRatio", title: "Grind setting vs ratio".localized),
        shotTimeBuckets: [],
        weeklyRatings: [],
        waterTempVsRating: .empty(id: "waterTempVsRating", title: "Water temp vs rating".localized),
        extractionTimeOverTime: .empty(id: "extractionTime", title: "Extraction time over time".localized),
        topCoffees: [],
        weatherVsRating: .empty(id: "weatherVsRating", title: "Weather vs rating".localized),
        topBrews: [],
        shotTimeInsight: "",
        weeklyRatingInsight: ""
    )
    private(set) var cachedBeansWithBrews: [(id: UUID, name: String)] = []
    private var updateTask: Task<Void, Never>?

    func update(brews: [BrewEntry]) {
        updateTask?.cancel()
        let options = filterOptions
        // Snapshot value-type metrics off the model objects before leaving MainActor.
        let records = brews.map(ChartBrewRecord.init)
        updateTask = Task {
            let (snapshot, beans) = await Task.detached(priority: .userInitiated) {
                let snapshot = ChartAnalyticsService.buildDashboard(from: records, options: options)
                let beans = ChartAnalyticsService.beansWithBrews(
                    in: ChartAnalyticsService.filter(
                        records,
                        options: ChartFilterOptions(timeRange: options.timeRange, brewStyle: options.brewStyle)
                    )
                )
                return (snapshot, beans)
            }.value
            guard !Task.isCancelled else { return }
            dashboard = snapshot
            cachedBeansWithBrews = beans
        }
    }

    func setTimeRange(_ range: ChartTimeRange) {
        filterOptions.timeRange = range
    }

    func setBrewStyle(_ style: BrewFlowType?) {
        filterOptions.brewStyle = style
    }

    func setBeanId(_ beanId: UUID?) {
        filterOptions.beanId = beanId
        filterOptions.coffeeNameFilter = nil
    }

    func setCoffeeNameFilter(_ name: String?) {
        filterOptions.coffeeNameFilter = name
        if name != nil {
            filterOptions.beanId = nil
        }
    }

    func beansWithBrews(from allBrews: [BrewEntry]) -> [(id: UUID, name: String)] {
        if !cachedBeansWithBrews.isEmpty {
            return cachedBeansWithBrews
        }
        let records = allBrews.map(ChartBrewRecord.init)
        let filtered = ChartAnalyticsService.filter(
            records,
            options: ChartFilterOptions(timeRange: filterOptions.timeRange, brewStyle: filterOptions.brewStyle)
        )
        return ChartAnalyticsService.beansWithBrews(in: filtered)
    }
}

private extension ChartSeries {
    static func empty(id: String, title: String) -> ChartSeries {
        ChartSeries(
            id: id,
            title: title,
            insight: "",
            points: [],
            rollingAverage: [],
            trendLine: nil,
            referenceY: nil,
            minimumSamples: 1
        )
    }
}
