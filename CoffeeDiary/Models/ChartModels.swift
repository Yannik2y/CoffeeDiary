import Foundation

enum ChartTimeRange: String, CaseIterable, Identifiable {
    case last7Days
    case last30Days
    case last90Days
    case all

    var id: String { rawValue }

    var dayCount: Int? {
        switch self {
        case .last7Days: return 7
        case .last30Days: return 30
        case .last90Days: return 90
        case .all: return nil
        }
    }

    var title: String {
        switch self {
        case .last7Days: return "7d".localized
        case .last30Days: return "30d".localized
        case .last90Days: return "90d".localized
        case .all: return "All".localized
        }
    }
}

struct ChartPoint: Identifiable, Equatable {
    let id: UUID
    let brewId: UUID
    let date: Date?
    let x: Double
    let y: Double
    let label: String
    let shotType: ShotType?

    init(
        brewId: UUID,
        date: Date? = nil,
        x: Double,
        y: Double,
        label: String,
        shotType: ShotType? = nil
    ) {
        self.id = brewId
        self.brewId = brewId
        self.date = date
        self.x = x
        self.y = y
        self.label = label
        self.shotType = shotType
    }
}

struct ChartTrendLine {
    let start: (x: Double, y: Double)
    let end: (x: Double, y: Double)
    let r2: Double
}

struct ChartSeries: Identifiable {
    let id: String
    let title: String
    let insight: String
    let points: [ChartPoint]
    let rollingAverage: [ChartPoint]
    let trendLine: ChartTrendLine?
    let referenceY: Double?
    let minimumSamples: Int

    var hasEnoughData: Bool { points.count >= minimumSamples }
}

struct KPIStat: Identifiable, Equatable {
    let id: String
    let title: String
    let value: String
    let delta: String?
}

struct DimensionBreakdown: Identifiable, Equatable {
    let id: String
    let name: String
    let averageRating: Double
    let count: Int
    let beanId: UUID?
    let coffeeName: String?
}

struct ShotTimeBucket: Identifiable, Equatable {
    let id: String
    let bucketStart: Int
    let shotType: ShotType
    let count: Int
}

struct WeeklyRatingBucket: Identifiable, Equatable {
    let id: Date
    let weekStart: Date
    let averageRating: Double
    let count: Int
}

struct TopBrewRow: Identifiable, Equatable {
    let id: UUID
    let coffeeName: String
    let rating: Int
    let ratioLabel: String
    let date: Date
}

struct ChartsDashboardSnapshot {
    let kpis: [KPIStat]
    let filteredBrews: [BrewEntry]
    let espressoBrews: [BrewEntry]
    let filterBrews: [BrewEntry]
    let ratioOverTime: ChartSeries
    let grindVsRatio: ChartSeries
    let shotTimeBuckets: [ShotTimeBucket]
    let weeklyRatings: [WeeklyRatingBucket]
    let waterTempVsRating: ChartSeries
    let extractionTimeOverTime: ChartSeries
    let topCoffees: [DimensionBreakdown]
    let weatherVsRating: ChartSeries
    let topBrews: [TopBrewRow]
    let shotTimeInsight: String
    let weeklyRatingInsight: String
}

struct ChartFilterOptions: Equatable {
    var timeRange: ChartTimeRange = .all
    var brewStyle: BrewFlowType? = nil
    var beanId: UUID? = nil
    var coffeeNameFilter: String? = nil
}
