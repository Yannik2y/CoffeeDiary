import SwiftUI
import SwiftData

struct BrewEntryFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var beans: [Bean]
    @Query private var grinders: [Grinder]
    @Query private var machines: [Machine]
    @Query private var brewers: [Brewer]
    
    let flow: BrewFlowType
    
    @State private var stepIndex: Int = 0
    
    // Collected answers
    @State private var coffeeName: String = ""
    @State private var shotType: ShotType = .double
    @State private var grinderSetting: Double = 2.0
    @State private var doseGrams: Double = 18.0
    @State private var yieldGrams: Double = 36.0
    @State private var brewTimeSeconds: Int = 0
    @State private var grinderTimerSeconds: Double = 0
    @State private var notes: String = ""
    @State private var rating: Int = 0
    @State private var selectedBean: Bean?
    @State private var selectedGrinder: Grinder?
    @State private var selectedMachine: Machine?
    @State private var selectedBrewer: Brewer?
    @State private var bloomWaterGrams: Double = 0
    @State private var bloomTimeSeconds: Int = 0
    @State private var totalWaterGrams: Double = 0
    @State private var waterTemperatureCelsius: Double = 0
    @State private var preInfusionTimeSeconds: Int = 0
    @State private var brewPressureBar: Double = 0
    
    @State private var isTiming = false
    @State private var timerStartDate: Date? = nil
    @State private var showingConfig = false
    @State private var showingBrewerForm = false
    @StateObject private var weatherViewModel = WeatherCaptureViewModel()
    @State private var weatherSnapshot: WeatherSnapshot?
    
    @Query(sort: \BrewEntry.createdAt, order: .reverse) private var allEntries: [BrewEntry]
    
    @State private var flowConfig = FlowConfiguration.load()
    
    init(flow: BrewFlowType) {
        self.flow = flow
    }
    
    private func loadLastEntryDefaults() {
        let lastEntry: BrewEntry? = {
            if flow == .espresso {
                // For espresso: find the most recent espresso entry
                guard let mostRecentEspresso = allEntries.first(where: { $0.brewStyle == .espresso }) else {
                    return allEntries.first
                }
                
                // Find the most recent entry with the same shot type
                let shotType = mostRecentEspresso.shotType
                if let matchingShotEntry = allEntries.first(where: { 
                    $0.brewStyle == .espresso && $0.shotType == shotType 
                }) {
                    return matchingShotEntry
                }
                
                // Fallback to most recent espresso entry
                return mostRecentEspresso
            } else {
                // For filter: just get the last filter entry
                return allEntries.first(where: { $0.brewStyle == .filter }) ?? allEntries.first
            }
        }()
        
        guard let lastEntry = lastEntry else { return }
        
        coffeeName = lastEntry.coffeeName
        grinderSetting = lastEntry.grinderSetting
        shotType = lastEntry.shotType
        doseGrams = lastEntry.doseGrams
        selectedBean = lastEntry.bean
        selectedGrinder = lastEntry.grinder
        selectedMachine = lastEntry.machine
        grinderTimerSeconds = lastEntry.grinderTimerSeconds
        yieldGrams = lastEntry.yieldGrams
        brewTimeSeconds = lastEntry.brewTimeSeconds
        selectedBrewer = lastEntry.brewer
        bloomWaterGrams = lastEntry.bloomWaterGrams
        bloomTimeSeconds = lastEntry.bloomTimeSeconds
        totalWaterGrams = lastEntry.totalWaterInputGrams
        waterTemperatureCelsius = lastEntry.waterTemperatureCelsius
        preInfusionTimeSeconds = lastEntry.preInfusionTimeSeconds
        brewPressureBar = lastEntry.brewPressureBar
    }
    
    private func loadDefaultsForShotType(_ shotType: ShotType) {
        guard flow == .espresso else { return }
        
        // Find the most recent entry with this shot type
        guard let matchingEntry = allEntries.first(where: { 
            $0.brewStyle == .espresso && $0.shotType == shotType 
        }) else { return }
        
        // Update values from the matching entry
        coffeeName = matchingEntry.coffeeName
        grinderSetting = matchingEntry.grinderSetting
        doseGrams = matchingEntry.doseGrams
        selectedBean = matchingEntry.bean
        selectedGrinder = matchingEntry.grinder
        selectedMachine = matchingEntry.machine
        grinderTimerSeconds = matchingEntry.grinderTimerSeconds
        yieldGrams = matchingEntry.yieldGrams
        brewTimeSeconds = matchingEntry.brewTimeSeconds
        preInfusionTimeSeconds = matchingEntry.preInfusionTimeSeconds
        brewPressureBar = matchingEntry.brewPressureBar
    }
    
    private var steps: [Step] {
        var s: [Step] = []
        if flow == .espresso {
            if flowConfig.espressoCoffee { s.append(.coffee) }
            if flowConfig.espressoShotType { s.append(.shotType) }
            if flowConfig.espressoGrinder {
                s.append(.grinderSetting)
                if flowConfig.espressoGrinderTimer { s.append(.grinderTimer) }
            }
            if flowConfig.espressoDose { s.append(.dose) }
            if flowConfig.espressoTime { s.append(.time) }
            if flowConfig.espressoPreInfusionTime { s.append(.preInfusionTime) }
            if flowConfig.espressoBrewPressure { s.append(.brewPressure) }
            if flowConfig.espressoYield { s.append(.yield) }
            if flowConfig.espressoGear { s.append(.gear) }
            if flowConfig.espressoNotes { s.append(.notes) }
        } else {
            if flowConfig.filterCoffee { s.append(.coffee) }
            if flowConfig.filterGrinder {
                s.append(.grinderSetting)
                if flowConfig.filterGrinderTimer { s.append(.grinderTimer) }
            }
            if flowConfig.filterBrewer { s.append(.brewerSelection) }
            if flowConfig.filterDose { s.append(.dose) }
            if flowConfig.filterTime { s.append(.time) }
            if flowConfig.filterYield { s.append(.yield) }
            if flowConfig.filterBloom { s.append(.bloom) }
            if flowConfig.filterTotalWater { s.append(.totalWater) }
            if flowConfig.filterWaterTemp { s.append(.waterTemp) }
            if flowConfig.filterGear { s.append(.gear) }
            if flowConfig.filterNotes { s.append(.notes) }
        }
        if flow == .espresso ? flowConfig.espressoRating : flowConfig.filterRating {
            s.append(.rating)
        }
        if flow == .espresso ? flowConfig.espressoWeather : flowConfig.filterWeather {
            s.append(.weather)
        }
        s.append(.review)
        return s
    }

    private var shouldShowShotSummary: Bool {
        flow == .espresso && flowConfig.espressoShotType
    }
    
    private var doseRange: ClosedRange<Double> {
        flow == .espresso ? 5...25 : 5...60
    }
    
    private var yieldRange: ClosedRange<Double> {
        flow == .espresso ? 15...70 : 150...700
    }
    
    private var grinderTimerRange: ClosedRange<Double> {
        flow == .espresso ? 0...30 : 0...60
    }
    
    private var bloomWaterRange: ClosedRange<Double> { 0...200 }
    private var totalWaterRange: ClosedRange<Double> { 0...1000 }
    private var waterTempRange: ClosedRange<Double> { 0...100 }
    private let preInfusionTimeRange: ClosedRange<Int> = 0...30
    private let brewPressureRange: ClosedRange<Double> = 0...12
    
    private var doseBinding: Binding<Double> {
        Binding(
            get: { min(max(doseGrams, doseRange.lowerBound), doseRange.upperBound) },
            set: { doseGrams = min(max($0, doseRange.lowerBound), doseRange.upperBound) }
        )
    }
    
    private var yieldBinding: Binding<Double> {
        Binding(
            get: { min(max(yieldGrams, yieldRange.lowerBound), yieldRange.upperBound) },
            set: { yieldGrams = min(max($0, yieldRange.lowerBound), yieldRange.upperBound) }
        )
    }
    
    private var grinderTimerBinding: Binding<Double> {
        Binding(
            get: { min(max(grinderTimerSeconds, grinderTimerRange.lowerBound), grinderTimerRange.upperBound) },
            set: { grinderTimerSeconds = min(max($0, grinderTimerRange.lowerBound), grinderTimerRange.upperBound) }
        )
    }
    
    private var bloomWaterBinding: Binding<Double> {
        Binding(
            get: { min(max(bloomWaterGrams, bloomWaterRange.lowerBound), bloomWaterRange.upperBound) },
            set: { bloomWaterGrams = min(max($0, bloomWaterRange.lowerBound), bloomWaterRange.upperBound) }
        )
    }
    
    private var totalWaterBinding: Binding<Double> {
        Binding(
            get: { min(max(totalWaterGrams, totalWaterRange.lowerBound), totalWaterRange.upperBound) },
            set: { totalWaterGrams = min(max($0, totalWaterRange.lowerBound), totalWaterRange.upperBound) }
        )
    }
    
    private var waterTempBinding: Binding<Double> {
        Binding(
            get: { min(max(waterTemperatureCelsius, waterTempRange.lowerBound), waterTempRange.upperBound) },
            set: { waterTemperatureCelsius = min(max($0, waterTempRange.lowerBound), waterTempRange.upperBound) }
        )
    }

    private var brewPressureBinding: Binding<Double> {
        Binding(
            get: { min(max(brewPressureBar, brewPressureRange.lowerBound), brewPressureRange.upperBound) },
            set: { brewPressureBar = min(max($0, brewPressureRange.lowerBound), brewPressureRange.upperBound) }
        )
    }
    
    
    private var progressHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Step %d of %d".localized(with: stepIndex + 1, steps.count))
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.cardBackground)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.accent)
                        .frame(width: geometry.size.width * CGFloat(stepIndex + 1) / CGFloat(steps.count), height: 6)
                }
            }
            .frame(height: 6)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                progressHeader
                Group {
                    switch steps[stepIndex] {
                    case .coffee: questionCoffee
                    case .shotType: questionShotType
                    case .grinderSetting: questionGrinder
                    case .grinderTimer: questionGrinderTimer
                    case .dose: questionDose
                    case .yield: questionYield
                    case .time: questionTime
                case .preInfusionTime: questionPreInfusionTime
                case .brewPressure: questionBrewPressure
                    case .brewerSelection: questionBrewer
                    case .bloom: questionBloom
                    case .totalWater: questionTotalWater
                    case .waterTemp: questionWaterTemp
                    case .gear: questionGear
                    case .notes: questionNotes
                    case .rating: questionRating
                case .weather: questionWeather
                    case .review: reviewView
                    }
                }
                .animation(.easeInOut, value: stepIndex)
                Spacer(minLength: 0)
                controls
            }
            .padding()
            .background(AppTheme.subtleBackground)
            .navigationTitle(flow.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingConfig = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingConfig) {
                FlowConfigurationView(flowType: flow)
            }
            .sheet(isPresented: $showingBrewerForm) {
                BrewerFormView { brewer in
                    modelContext.insert(brewer)
                    ErrorHandler.save(modelContext, errorMessage: "Failed to save brewer. Please try again.".localized)
                    selectedBrewer = brewer
                }
            }
            .onChange(of: showingConfig) { _, isShowing in
                if !isShowing { flowConfig = FlowConfiguration.load() }
            }
            .errorAlert()
            .onAppear {
                loadLastEntryDefaults()
                clampValuesToRanges()
            }
            .onChange(of: shotType) { oldValue, newValue in
                // When shot type changes, load defaults for the new shot type
                if flow == .espresso && oldValue != newValue {
                    loadDefaultsForShotType(newValue)
                    clampValuesToRanges()
                }
            }
            .onReceive(weatherViewModel.$snapshot) { snapshot in
                weatherSnapshot = snapshot
            }
            .onDisappear {
                if isTiming, let start = timerStartDate {
                    brewTimeSeconds = max(0, Int(Date().timeIntervalSince(start)))
                    isTiming = false
                }
            }
        }
    }
    
    // MARK: - Steps
    private var questionCoffee: some View {
        VStack(spacing: 12) {
            Text("What coffee are you brewing?".localized)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            TextField("Coffee name".localized, text: $coffeeName)
                .textFieldStyle(.roundedBorder)
        }
    }
    
    private var questionShotType: some View {
        VStack(spacing: 12) {
            Text("Shot size?".localized)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            ShotTypePicker(shotType: $shotType)
        }
    }
    
    private var questionGrinder: some View {
        VStack(spacing: 12) {
            Text("Grinder setting?".localized)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Stepper(value: $grinderSetting, in: 0...20, step: 0.1) {
                Text("\(Formatters.number.string(from: NSNumber(value: grinderSetting)) ?? String(grinderSetting))")
            }
        }
    }
    
    private var questionGrinderTimer: some View {
        VStack(spacing: 12) {
            Text("Grinder timer (seconds)?".localized)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Slider(value: grinderTimerBinding, in: grinderTimerRange, step: 0.1)
            HStack {
                Text("\(Formatters.number.string(from: NSNumber(value: grinderTimerSeconds)) ?? String(format: "%.1f", grinderTimerSeconds)) s")
                Spacer()
                if grinderTimerRange.upperBound > 0 {
                    Text("Range %.1f–%.1f s".localized(with: grinderTimerRange.lowerBound, grinderTimerRange.upperBound))
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
    }
    
    private var questionBrewer: some View {
        VStack(spacing: 12) {
            Text("Which brewer are you using?".localized)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            if brewers.isEmpty {
                Text("No brewers configured yet. Add one from the Equipment menu.".localized)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                Button("Add Brewer".localized) {
                    showingBrewerForm = true
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
            } else {
                Picker("Brewer".localized, selection: Binding(
                    get: { selectedBrewer?.id ?? PickerSelection.none },
                    set: { id in
                        selectedBrewer = id == PickerSelection.none ? nil : brewers.first(where: { $0.id == id })
                    }
                )) {
                    Text("None".localized).tag(PickerSelection.none)
                    ForEach(brewers) { brewer in
                        Text(brewer.name).tag(brewer.id)
                    }
                }
                .pickerStyle(.navigationLink)
            }
        }
    }
    
    private var questionBloom: some View {
        VStack(spacing: 12) {
            Text("Bloom details".localized)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Slider(value: bloomWaterBinding, in: bloomWaterRange, step: 1)
            HStack {
                Text("Bloom water: %d g".localized(with: Int(bloomWaterGrams)))
                Spacer()
                Text("Bloom time: %d s".localized(with: bloomTimeSeconds))
            }
            Stepper(value: $bloomTimeSeconds, in: 0...120, step: 1) {
                Text("Adjust bloom time".localized)
            }
        }
    }
    
    private var questionTotalWater: some View {
        VStack(spacing: 12) {
            Text("Total brew water".localized)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Slider(value: totalWaterBinding, in: totalWaterRange, step: 5)
            Text("\(Int(totalWaterGrams)) g")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var questionWaterTemp: some View {
        VStack(spacing: 12) {
            Text("Water temperature".localized)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Slider(value: waterTempBinding, in: waterTempRange, step: 1)
            Text("\(Int(waterTemperatureCelsius)) °C")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var questionDose: some View {
        VStack(spacing: 12) {
            Text("Dose (g)?".localized)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Slider(value: doseBinding, in: doseRange, step: 0.1)
            HStack {
                Text(Formatters.number.string(from: NSNumber(value: doseGrams)) ?? String(doseGrams))
                Spacer()
                Text("\(Int(doseRange.lowerBound))–\(Int(doseRange.upperBound)) g")
                    .foregroundStyle(AppTheme.textSecondary)
                    .font(.caption)
            }
        }
    }
    
    private var questionYield: some View {
        VStack(spacing: 12) {
            Text(flow == .espresso ? "Yield (g)?".localized : "Brewed amount (g)?".localized)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Slider(value: yieldBinding, in: yieldRange, step: 0.5)
            HStack {
                Text(Formatters.number.string(from: NSNumber(value: yieldGrams)) ?? String(yieldGrams))
                Spacer()
                Text("Ratio".localized + " \(Formatters.ratioString(dose: doseGrams, yield: yieldGrams))")
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }
    
    private var questionTime: some View {
        VStack(spacing: 20) {
            Text(flow == .espresso ? "Shot time".localized : "Brew duration".localized)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            TimelineView(.periodic(from: Date(), by: 1)) { context in
                let displayed = {
                    if isTiming, let start = timerStartDate {
                        let elapsed = max(0, Int(context.date.timeIntervalSince(start).rounded()))
                        return Formatters.secondsString(elapsed)
                    } else {
                        return Formatters.secondsString(brewTimeSeconds)
                    }
                }()
                HStack {
                    Spacer()
                    Text(displayed)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Spacer()
                }
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient(colors: [AppTheme.accentSecondary.opacity(0.18), AppTheme.cardBackground],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                )
            }
            VStack(spacing: 16) {
                Button(isTiming ? "Stop".localized : "Start".localized) { toggleTimer() }
                    .font(.title.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(width: 120, height: 120)
                    .background(isTiming ? Color.red : AppTheme.accent)
                    .clipShape(Circle())
                    .buttonStyle(.plain)
                Button("Reset".localized) { resetTimer() }
                    .buttonStyle(.bordered)
                    .disabled(isTiming == false && brewTimeSeconds == 0)
                    .font(.title3.weight(.medium))
                    .frame(height: 56)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    private var questionPreInfusionTime: some View {
        VStack(spacing: 12) {
            Text("Pre-infusion time".localized)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Slider(value: Binding(
                get: { Double(preInfusionTimeSeconds) },
                set: { preInfusionTimeSeconds = Int($0.rounded()) }
            ), in: Double(preInfusionTimeRange.lowerBound)...Double(preInfusionTimeRange.upperBound), step: 1)
            HStack {
                Text("\(preInfusionTimeSeconds) " + "s".localized)
                Spacer()
                Text("Range %d–%d s".localized(with: preInfusionTimeRange.lowerBound, preInfusionTimeRange.upperBound))
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }
    
    private var questionBrewPressure: some View {
        VStack(spacing: 12) {
            Text("Brew pressure".localized)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Slider(value: brewPressureBinding, in: brewPressureRange, step: 0.1)
            HStack {
                Text(String(format: "%.1f bar", brewPressureBar))
                Spacer()
                Text("Typical espresso bars".localized)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }
    
    private var questionGear: some View {
        VStack(spacing: 12) {
            Text("Gear (optional)".localized)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Picker("Bean".localized, selection: Binding(
                get: { selectedBean?.id ?? PickerSelection.none },
                set: { id in
                    selectedBean = id == PickerSelection.none ? nil : beans.first(where: { $0.id == id })
                }
            )) {
                Text("None".localized).tag(PickerSelection.none)
                ForEach(beans.filter { !$0.isArchived }) { b in Text(b.name).tag(b.id) }
            }
            Picker("Grinder".localized, selection: Binding(
                get: { selectedGrinder?.id ?? PickerSelection.none },
                set: { id in
                    selectedGrinder = id == PickerSelection.none ? nil : grinders.first(where: { $0.id == id })
                }
            )) {
                Text("None".localized).tag(PickerSelection.none)
                ForEach(grinders) { g in Text(g.name).tag(g.id) }
            }
            if flow == .espresso {
                Picker("Machine".localized, selection: Binding(
                    get: { selectedMachine?.id ?? PickerSelection.none },
                    set: { id in
                        selectedMachine = id == PickerSelection.none ? nil : machines.first(where: { $0.id == id })
                    }
                )) {
                    Text("None".localized).tag(PickerSelection.none)
                    ForEach(machines) { m in Text(m.name).tag(m.id) }
                }
            }
        }
    }
    
    private var questionNotes: some View {
        VStack(spacing: 12) {
            Text("Any notes?".localized)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            TextField("Optional notes".localized, text: $notes, axis: .vertical)
                .textFieldStyle(.roundedBorder)
        }
    }
    
    private var questionRating: some View {
        VStack(spacing: 16) {
            Text("Rate this brew?".localized)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            StarRatingView(rating: $rating, editable: true, size: 40)
        }
    }
    
    private var questionWeather: some View {
        VStack(spacing: 12) {
            Text("Weather".localized)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Capture weather context".localized)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            weatherStatusView
            
            if let snapshot = weatherSnapshot {
                weatherSummaryView(snapshot)
            }
            
            Button {
                weatherViewModel.refresh()
            } label: {
                Label("Fetch current weather".localized, systemImage: "location.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isWeatherButtonDisabled)
        }
    }
    
    @ViewBuilder
    private var weatherStatusView: some View {
        switch weatherViewModel.phase {
        case .idle:
            weatherStatusText("Tap \"Fetch current weather\" to save temperature and humidity for this brew.".localized, color: AppTheme.textSecondary)
        case .requestingPermission:
            weatherStatusText("Requesting location permission…".localized, color: AppTheme.textSecondary)
        case .locating:
            weatherStatusText("Locating you…".localized, color: AppTheme.textSecondary)
        case .fetching:
            weatherStatusText("Fetching weather data…".localized, color: AppTheme.textSecondary)
        case .success:
            weatherStatusText("Weather data saved".localized, color: AppTheme.accent)
        case .failure(let error):
            weatherStatusText(error.message, color: .red)
        }
    }
    
    private func weatherStatusText(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var isWeatherButtonDisabled: Bool {
        switch weatherViewModel.phase {
        case .requestingPermission, .locating, .fetching:
            return true
        default:
            return false
        }
    }
    
    @ViewBuilder
    private func weatherSummaryView(_ snapshot: WeatherSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Weather location".localized)
                Spacer()
                Text(snapshot.locationName)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            HStack {
                Text("Temperature".localized)
                Spacer()
                Text(String(format: "%.1f °C", snapshot.temperatureCelsius))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            HStack {
                Text("Humidity".localized)
                Spacer()
                Text(String(format: "%.0f %%", snapshot.humidityPercent))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Text("Weather last updated %@".localized(with: snapshot.timestamp.formatted(date: .abbreviated, time: .shortened)))
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.cardBackground)
        )
    }
    
    private var reviewView: some View {
        VStack(spacing: 12) {
            Text("Review".localized)
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
            VStack(spacing: 8) {
                HStack { Text("Coffee".localized); Spacer(); Text(coffeeName) }
                HStack { Text("Style".localized); Spacer(); Text(flow.title) }
                if shouldShowShotSummary {
                    HStack { Text("Shot".localized); Spacer(); Text(shotType.displayName) }
                }
                HStack { Text("Grinder".localized); Spacer(); Text("\(grinderSetting, specifier: "%.1f")") }
                if grinderTimerSeconds > 0 {
                    HStack {
                        Text("Grinder timer".localized)
                        Spacer()
                        Text("\(Formatters.number.string(from: NSNumber(value: grinderTimerSeconds)) ?? String(format: "%.1f", grinderTimerSeconds)) s")
                    }
                }
                HStack { Text("Dose".localized); Spacer(); Text("\(doseGrams, specifier: "%.1f") g") }
                HStack { Text(flow == .espresso ? "Yield".localized : "Brewed".localized); Spacer(); Text("\(yieldGrams, specifier: "%.1f") g") }
                HStack { Text("Time".localized); Spacer(); Text(Formatters.secondsString(brewTimeSeconds)) }
                if flow == .espresso && flowConfig.espressoPreInfusionTime && preInfusionTimeSeconds > 0 {
                    HStack {
                        Text("Pre-infusion time".localized)
                        Spacer()
                        Text("\(preInfusionTimeSeconds) " + "s".localized)
                    }
                }
                if flow == .espresso && flowConfig.espressoBrewPressure && brewPressureBar > 0 {
                    HStack {
                        Text("Brew pressure".localized)
                        Spacer()
                        Text(String(format: "%.1f bar", brewPressureBar))
                    }
                }
                if let bean = selectedBean { HStack { Text("Bean".localized); Spacer(); Text(bean.name) } }
                if let grinder = selectedGrinder { HStack { Text("Grinder".localized); Spacer(); Text(grinder.name) } }
                if flow == .espresso, let machine = selectedMachine {
                    HStack { Text("Machine".localized); Spacer(); Text(machine.name) }
                }
                if flow == .filter, let brewer = selectedBrewer, flowConfig.filterBrewer {
                    HStack { Text("Brewer".localized); Spacer(); Text(brewer.name) }
                }
                if flow == .filter, flowConfig.filterBloom, bloomWaterGrams > 0 || bloomTimeSeconds > 0 {
                    HStack {
                        Text("Bloom".localized)
                        Spacer()
                        Text("\(Int(bloomWaterGrams)) g / \(bloomTimeSeconds) s")
                    }
                }
                if flow == .filter, flowConfig.filterTotalWater, totalWaterGrams > 0 {
                    HStack { Text("Total water".localized); Spacer(); Text("\(Int(totalWaterGrams)) g") }
                }
                if flow == .filter, flowConfig.filterWaterTemp, waterTemperatureCelsius > 0 {
                    HStack { Text("Water temp".localized); Spacer(); Text("\(Int(waterTemperatureCelsius)) °C") }
                }
                if let weather = weatherSnapshot {
                    Divider()
                        .background(AppTheme.textSecondary.opacity(0.2))
                    HStack {
                        Text("Weather".localized)
                        Spacer()
                        Text(weather.locationName)
                    }
                    HStack {
                        Text("Temperature".localized)
                        Spacer()
                        Text(String(format: "%.1f °C", weather.temperatureCelsius))
                    }
                    HStack {
                        Text("Humidity".localized)
                        Spacer()
                        Text(String(format: "%.0f %%", weather.humidityPercent))
                    }
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.cardBackground))
            if !notes.isEmpty {
                Text(notes).foregroundStyle(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if rating > 0 {
                HStack {
                    Text("Rating".localized)
                    Spacer()
                    StarRatingDisplayView(rating: rating, size: 20)
                }
            }
        }
    }
    
    // MARK: - Controls
    private var controls: some View {
        HStack {
            if stepIndex > 0 {
                Button("Back".localized) { stepIndex -= 1 }
                    .buttonStyle(.bordered)
            }
            Spacer()
            if steps[stepIndex] == .review {
                Button("Save".localized) { save() }
                    .buttonStyle(.borderedProminent)
                    .disabled(coffeeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || doseGrams <= 0)
            } else {
                Button("Next".localized) { stepIndex = min(stepIndex + 1, steps.count - 1) }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canProceedFrom(step: steps[stepIndex]))
            }
        }
    }
    
    private func canProceedFrom(step: Step) -> Bool {
        switch step {
        case .coffee: return !coffeeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .shotType: return true
        case .grinderSetting: return true
        case .dose: return doseGrams > 0
        case .yield: return true
        case .time: return true
        case .preInfusionTime: return true
        case .brewPressure: return true
        case .grinderTimer: return true
        case .brewerSelection: return true
        case .bloom: return true
        case .totalWater: return true
        case .waterTemp: return true
        case .gear: return true
        case .notes: return true
        case .rating: return true
        case .weather: return true
        case .review: return true
        }
    }
    
    private func clampValuesToRanges() {
        doseGrams = min(max(doseGrams, doseRange.lowerBound), doseRange.upperBound)
        yieldGrams = min(max(yieldGrams, yieldRange.lowerBound), yieldRange.upperBound)
        grinderTimerSeconds = min(max(grinderTimerSeconds, grinderTimerRange.lowerBound), grinderTimerRange.upperBound)
        bloomWaterGrams = min(max(bloomWaterGrams, bloomWaterRange.lowerBound), bloomWaterRange.upperBound)
        bloomTimeSeconds = min(max(bloomTimeSeconds, 0), 120)
        totalWaterGrams = min(max(totalWaterGrams, totalWaterRange.lowerBound), totalWaterRange.upperBound)
        waterTemperatureCelsius = min(max(waterTemperatureCelsius, waterTempRange.lowerBound), waterTempRange.upperBound)
        preInfusionTimeSeconds = min(max(preInfusionTimeSeconds, preInfusionTimeRange.lowerBound), preInfusionTimeRange.upperBound)
        brewPressureBar = min(max(brewPressureBar, brewPressureRange.lowerBound), brewPressureRange.upperBound)
    }
    
    // MARK: - Timer
    private func toggleTimer() {
        if isTiming {
            if let start = timerStartDate {
                brewTimeSeconds = max(0, Int(Date().timeIntervalSince(start).rounded()))
            }
            isTiming = false
            timerStartDate = nil
        } else {
            isTiming = true
            timerStartDate = Date()
        }
    }
    private func resetTimer() {
        brewTimeSeconds = 0
        isTiming = false
        timerStartDate = nil
    }
    
    // MARK: - Save
    private func save() {
        let entry = BrewEntry(
            coffeeName: coffeeName,
            grinderSetting: grinderSetting,
            shotType: flow == .espresso ? shotType : .double,
            doseGrams: doseGrams,
            yieldGrams: yieldGrams,
            brewTimeSeconds: brewTimeSeconds,
            grinderTimerSeconds: grinderTimerSeconds,
            bloomWaterGrams: flow == .filter ? bloomWaterGrams : 0,
            bloomTimeSeconds: flow == .filter ? bloomTimeSeconds : 0,
            totalWaterInputGrams: flow == .filter ? totalWaterGrams : 0,
            waterTemperatureCelsius: flow == .filter ? waterTemperatureCelsius : 0,
            preInfusionTimeSeconds: (flow == .espresso && flowConfig.espressoPreInfusionTime) ? preInfusionTimeSeconds : 0,
            brewPressureBar: (flow == .espresso && flowConfig.espressoBrewPressure) ? brewPressureBar : 0,
            brewStyle: flow,
            rating: rating,
            weatherTemperatureCelsius: weatherSnapshot?.temperatureCelsius,
            weatherHumidityPercent: weatherSnapshot?.humidityPercent,
            weatherLocationName: weatherSnapshot?.locationName,
            weatherCaptureDate: weatherSnapshot?.timestamp,
            notes: notes.isEmpty ? nil : notes,
            bean: selectedBean,
            grinder: selectedGrinder,
            machine: flow == .espresso ? selectedMachine : nil,
            brewer: flow == .filter ? selectedBrewer : nil
        )
        modelContext.insert(entry)
        ErrorHandler.save(modelContext, errorMessage: "Failed to save brew entry. Please try again.".localized) {
        dismiss()
        }
    }
    
    private enum Step {
        case coffee
        case shotType
        case grinderSetting
        case grinderTimer
        case dose
        case yield
        case time
        case preInfusionTime
        case brewPressure
        case brewerSelection
        case bloom
        case totalWater
        case waterTemp
        case gear
        case notes
        case rating
        case weather
        case review
    }
}



