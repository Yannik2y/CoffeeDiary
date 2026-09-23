import SwiftUI
import SwiftData
import Charts

struct ChartsView: View {
    @Query(sort: \BrewEntry.createdAt) private var brews: [BrewEntry]

    @State private var viewModel = ChartsViewModel()
    @State private var path = NavigationPath()
    @State private var selectedRatioDate: Date?
    @State private var selectedExtractionDate: Date?

    private var dashboard: ChartsDashboardSnapshot { viewModel.dashboard }
    private var styleFilter: BrewFlowType? { viewModel.filterOptions.brewStyle }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if brews.isEmpty {
                        ContentUnavailableView(
                            "No data".localized,
                            systemImage: "chart.xyaxis.line",
                            description: Text("Add a few brews to see trends.".localized)
                        )
                    } else {
                        KPIGrid(stats: dashboard.kpis)
                        filterControls
                        chartSections
                    }
                }
                .padding()
            }
            .background(AppTheme.subtleBackground)
            .navigationTitle("Stats".localized)
            .navigationDestination(for: UUID.self) { id in
                BrewDetailDestination(brewId: id, allBrews: brews)
            }
            .onAppear { refresh() }
            .onChange(of: brews.count) { _, _ in refresh() }
            .onChange(of: selectedRatioDate) { _, newValue in
                selectBrew(from: dashboard.ratioOverTime.points, date: newValue)
            }
            .onChange(of: selectedExtractionDate) { _, newValue in
                selectBrew(from: dashboard.extractionTimeOverTime.points, date: newValue)
            }
        }
    }

    // MARK: - Filters

    private var filterControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Time range".localized, selection: timeRangeBinding) {
                ForEach(ChartTimeRange.allCases) { range in
                    Text(range.title).tag(range)
                }
            }
            .pickerStyle(.segmented)

            Picker("Brew Style".localized, selection: brewStyleBinding) {
                Text("All".localized).tag(Optional<BrewFlowType>.none)
                Text("Espresso".localized).tag(Optional<BrewFlowType>.some(.espresso))
                Text("Filter".localized).tag(Optional<BrewFlowType>.some(.filter))
            }
            .pickerStyle(.segmented)

            if !viewModel.beansWithBrews(from: brews).isEmpty {
                Picker("Bean".localized, selection: beanBinding) {
                    Text("All beans".localized).tag(Optional<UUID>.none)
                    ForEach(viewModel.beansWithBrews(from: brews), id: \.id) { bean in
                        Text(bean.name).tag(Optional(bean.id))
                    }
                }
            }

            if let coffeeFilter = viewModel.filterOptions.coffeeNameFilter {
                HStack {
                    Text("Filtered to %@".localized(with: coffeeFilter))
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                    Spacer()
                    Button("Clear".localized) {
                        viewModel.setCoffeeNameFilter(nil)
                        refresh()
                    }
                    .font(.caption)
                }
            }
        }
    }

    // MARK: - Charts

    @ViewBuilder
    private var chartSections: some View {
        ratioOverTimeCard

        if styleFilter == nil || styleFilter == .espresso {
            grindVsRatioCard
            shotTimeDistributionCard
        }

        if styleFilter == nil || styleFilter == .filter {
            waterTempCard
        }

        extractionTimeCard
        weeklyRatingCard

        if !dashboard.topCoffees.isEmpty {
            topCoffeesCard
        }

        if dashboard.weatherVsRating.hasEnoughData {
            weatherCard
        }

        if !dashboard.topBrews.isEmpty {
            topBrewsCard
        }
    }

    private var ratioOverTimeCard: some View {
        ChartCard(
            title: dashboard.ratioOverTime.title,
            insight: dashboard.ratioOverTime.insight,
            minimumSamples: dashboard.ratioOverTime.minimumSamples,
            sampleCount: dashboard.ratioOverTime.points.count,
            explanation: "Shows brew ratio (yield ÷ dose) over time. Espresso includes a dashed ~1:2 reference line.".localized
        ) {
            Chart {
                ForEach(dashboard.ratioOverTime.points) { point in
                    PointMark(
                        x: .value("Date", point.date ?? .now, unit: .day),
                        y: .value("Ratio", point.y)
                    )
                    .foregroundStyle(AppTheme.accent)
                    .symbolSize(40)
                }

                ForEach(dashboard.ratioOverTime.rollingAverage) { point in
                    LineMark(
                        x: .value("Date", point.date ?? .now, unit: .day),
                        y: .value("Rolling avg", point.y)
                    )
                    .foregroundStyle(AppTheme.accentSecondary)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.linear)
                }

                if let reference = dashboard.ratioOverTime.referenceY {
                    RuleMark(y: .value("Target", reference))
                        .foregroundStyle(AppTheme.accentSecondary.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }
            }
            .chartXSelection(value: $selectedRatioDate)
            .chartYScale(domain: ratioYDomain)
            .frame(height: 220)
        }
    }

    private var grindVsRatioCard: some View {
        ChartCard(
            title: dashboard.grindVsRatio.title,
            insight: dashboard.grindVsRatio.insight,
            minimumSamples: dashboard.grindVsRatio.minimumSamples,
            sampleCount: dashboard.grindVsRatio.points.count,
            explanation: "Plots grind setting against brew ratio for espresso shots, with an optional trend line.".localized
        ) {
            scatterChart(
                points: dashboard.grindVsRatio.points,
                xLabel: "Grind",
                yLabel: "Ratio",
                trendLine: dashboard.grindVsRatio.trendLine
            )
            .frame(height: 220)
        }
    }

    private var shotTimeDistributionCard: some View {
        ChartCard(
            title: "Shot time distribution".localized,
            insight: dashboard.shotTimeInsight,
            minimumSamples: 2,
            sampleCount: dashboard.espressoTimedBrewCount,
            explanation: "Shows how often espresso shot times fall into each band, grouped by shot type.".localized
        ) {
            Chart(dashboard.shotTimeBuckets) { bucket in
                BarMark(
                    x: .value("Seconds", bucket.bucketStart),
                    y: .value("Count", bucket.count)
                )
                .foregroundStyle(by: .value("Shot", bucket.shotType.displayName))
            }
            .chartForegroundStyleScale([
                ShotType.single.displayName: AppTheme.accent,
                ShotType.double.displayName: AppTheme.accentSecondary,
                ShotType.triple.displayName: AppTheme.accent.opacity(0.6)
            ])
            .frame(height: 200)
        }
    }

    private var waterTempCard: some View {
        ChartCard(
            title: dashboard.waterTempVsRating.title,
            insight: dashboard.waterTempVsRating.insight,
            minimumSamples: dashboard.waterTempVsRating.minimumSamples,
            sampleCount: dashboard.waterTempVsRating.points.count,
            explanation: "Compares brew water temperature (°C) with your star rating for filter brews.".localized
        ) {
            scatterChart(
                points: dashboard.waterTempVsRating.points,
                xLabel: "Temp",
                yLabel: "Rating",
                trendLine: dashboard.waterTempVsRating.trendLine
            )
            .frame(height: 200)
        }
    }

    private var extractionTimeCard: some View {
        ChartCard(
            title: dashboard.extractionTimeOverTime.title,
            insight: dashboard.extractionTimeOverTime.insight,
            minimumSamples: dashboard.extractionTimeOverTime.minimumSamples,
            sampleCount: dashboard.extractionTimeOverTime.points.count,
            explanation: "Tracks extraction or brew time over the selected period, with a rolling average.".localized
        ) {
            Chart {
                ForEach(dashboard.extractionTimeOverTime.points) { point in
                    PointMark(
                        x: .value("Date", point.date ?? .now, unit: .day),
                        y: .value("Seconds", point.y)
                    )
                    .foregroundStyle(AppTheme.accent)
                    .symbolSize(40)
                }

                ForEach(dashboard.extractionTimeOverTime.rollingAverage) { point in
                    LineMark(
                        x: .value("Date", point.date ?? .now, unit: .day),
                        y: .value("Rolling avg", point.y)
                    )
                    .foregroundStyle(AppTheme.accentSecondary)
                    .interpolationMethod(.linear)
                }
            }
            .chartXSelection(value: $selectedExtractionDate)
            .frame(height: 200)
        }
    }

    private var weeklyRatingCard: some View {
        ChartCard(
            title: "Weekly avg rating".localized,
            insight: dashboard.weeklyRatingInsight,
            minimumSamples: 1,
            sampleCount: dashboard.weeklyRatings.count,
            explanation: "Average star rating per calendar week for rated brews in this period.".localized
        ) {
            Chart(dashboard.weeklyRatings) { bucket in
                BarMark(
                    x: .value("Week", bucket.weekStart, unit: .weekOfYear),
                    y: .value("Rating", bucket.averageRating)
                )
                .foregroundStyle(AppTheme.accent)
                .annotation(position: .top) {
                    if bucket.count < 3 {
                        Text("n=%d".localized(with: bucket.count))
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
            .chartYScale(domain: 0...5)
            .frame(height: 200)
        }
    }

    private var topCoffeesCard: some View {
        ChartCard(
            title: "Top coffees by rating".localized,
            insight: "Tap a bar to filter the dashboard.".localized,
            minimumSamples: 1,
            sampleCount: dashboard.topCoffees.count,
            explanation: "Beans or coffee names with enough rated brews, ranked by average stars. Tap a bar to filter.".localized
        ) {
            Chart(dashboard.topCoffees) { item in
                BarMark(
                    x: .value("Rating", item.averageRating),
                    y: .value("Coffee", item.name)
                )
                .foregroundStyle(AppTheme.accent)
            }
            .chartXScale(domain: 0...5)
            .frame(height: CGFloat(max(160, dashboard.topCoffees.count * 36)))
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            guard let plotFrame = proxy.plotFrame else { return }
                            let origin = geometry[plotFrame].origin
                            let y = location.y - origin.y
                            if let name: String = proxy.value(atY: y),
                               let item = dashboard.topCoffees.first(where: { $0.name == name }) {
                                if let beanId = item.beanId {
                                    viewModel.setBeanId(beanId)
                                } else {
                                    viewModel.setCoffeeNameFilter(item.coffeeName ?? item.name)
                                }
                                HapticFeedback.selection()
                                refresh()
                            }
                        }
                }
            }
        }
    }

    private var weatherCard: some View {
        ChartCard(
            title: dashboard.weatherVsRating.title,
            insight: dashboard.weatherVsRating.insight,
            minimumSamples: dashboard.weatherVsRating.minimumSamples,
            sampleCount: dashboard.weatherVsRating.points.count,
            explanation: "Outdoor air temperature from the optional weather step versus your star rating.".localized
        ) {
            scatterChart(
                points: dashboard.weatherVsRating.points,
                xLabel: "Temp",
                yLabel: "Rating",
                trendLine: dashboard.weatherVsRating.trendLine
            )
            .frame(height: 200)
        }
    }

    private var topBrewsCard: some View {
        ChartCard(
            title: "Top brews".localized,
            insight: "Highest rated brews in this period.".localized,
            minimumSamples: 1,
            sampleCount: dashboard.topBrews.count,
            explanation: "Your highest-rated individual brews in the selected period. Tap a row to open details.".localized
        ) {
            VStack(spacing: 10) {
                ForEach(dashboard.topBrews) { brew in
                    Button {
                        navigateToBrew(brew.id)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(brew.coffeeName)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(AppTheme.textPrimary)
                                Text("\(brew.ratioLabel) · \(brew.date.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            Spacer()
                            StarRatingDisplayView(rating: brew.rating, size: 14)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Scatter chart with tap drill-down

    private func scatterChart(
        points: [ChartPoint],
        xLabel: String,
        yLabel: String,
        trendLine: ChartTrendLine?
    ) -> some View {
        Chart {
            ForEach(points) { point in
                PointMark(
                    x: .value(xLabel, point.x),
                    y: .value(yLabel, point.y)
                )
                .foregroundStyle(AppTheme.accent)
                .symbolSize(40)
            }

            if let trendLine {
                LineMark(x: .value(xLabel, trendLine.start.x), y: .value(yLabel, trendLine.start.y))
                LineMark(x: .value(xLabel, trendLine.end.x), y: .value(yLabel, trendLine.end.y))
                    .foregroundStyle(AppTheme.accentSecondary.opacity(0.7))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 4]))
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        guard let plotFrame = proxy.plotFrame else { return }
                        let origin = geometry[plotFrame].origin
                        let plotPoint = CGPoint(x: location.x - origin.x, y: location.y - origin.y)
                        guard let x: Double = proxy.value(atX: plotPoint.x),
                              let y: Double = proxy.value(atY: plotPoint.y) else { return }
                        if let nearest = nearestPoint(toX: x, y: y, in: points) {
                            navigateToBrew(nearest.brewId)
                        }
                    }
            }
        }
    }

    // MARK: - Bindings & helpers

    private var timeRangeBinding: Binding<ChartTimeRange> {
        Binding(
            get: { viewModel.filterOptions.timeRange },
            set: {
                viewModel.setTimeRange($0)
                refresh()
            }
        )
    }

    private var brewStyleBinding: Binding<BrewFlowType?> {
        Binding(
            get: { viewModel.filterOptions.brewStyle },
            set: {
                viewModel.setBrewStyle($0)
                refresh()
            }
        )
    }

    private var beanBinding: Binding<UUID?> {
        Binding(
            get: { viewModel.filterOptions.beanId },
            set: {
                viewModel.setBeanId($0)
                refresh()
            }
        )
    }

    private var ratioYDomain: ClosedRange<Double> {
        let values = dashboard.ratioOverTime.points.map(\.y)
        guard let minY = values.min(), let maxY = values.max() else {
            return 1.5...3.0
        }
        return max(1.0, minY - 0.2)...min(4.0, maxY + 0.2)
    }

    private func refresh() {
        viewModel.update(brews: brews)
    }

    private func selectBrew(from points: [ChartPoint], date: Date?) {
        guard let date else { return }
        let calendar = Calendar.current
        if let point = points.first(where: { point in
            guard let d = point.date else { return false }
            return calendar.isDate(d, inSameDayAs: date)
        }) {
            navigateToBrew(point.brewId)
        }
    }

    private func navigateToBrew(_ brewId: UUID) {
        HapticFeedback.selection()
        path.append(brewId)
    }

    private func nearestPoint(toX x: Double, y: Double, in points: [ChartPoint]) -> ChartPoint? {
        points.min(by: { lhs, rhs in
            let dl = hypot(lhs.x - x, lhs.y - y)
            let dr = hypot(rhs.x - x, rhs.y - y)
            return dl < dr
        })
    }
}

private struct BrewDetailDestination: View {
    let brewId: UUID
    let allBrews: [BrewEntry]

    var body: some View {
        if let entry = allBrews.first(where: { $0.id == brewId }) {
            BrewDetailView(entry: entry)
        } else {
            ContentUnavailableView("Brew not found".localized, systemImage: "cup.and.saucer")
        }
    }
}
