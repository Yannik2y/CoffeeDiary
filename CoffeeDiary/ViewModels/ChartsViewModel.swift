import Foundation
import Observation

@Observable
final class ChartsViewModel {
    var filterOptions = ChartFilterOptions()
    private(set) var dashboard = ChartsDashboardSnapshot(
        kpis: [],
        filteredBrews: [],
        espressoBrews: [],
        filterBrews: [],
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

    func update(brews: [BrewEntry]) {
        dashboard = ChartAnalyticsService.buildDashboard(from: brews, options: filterOptions)
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
        let filtered = ChartAnalyticsService.filter(
            allBrews,
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
