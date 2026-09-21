import SwiftUI
import SwiftData

struct BrewFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var beans: [Bean]
    @Query private var grinders: [Grinder]
    @Query private var machines: [Machine]
    @Query private var brewers: [Brewer]
    
    @State private var coffeeName: String = ""
    @State private var grinderSetting: Double = 2.0
    @State private var shotType: ShotType = .double
    @State private var doseGrams: Double = 18.0
    @State private var yieldGrams: Double = 36.0
    @State private var brewTimeSeconds: Int = 25
    @State private var grinderTimerSeconds: Double = 0
    @State private var brewStyle: BrewFlowType = .espresso
    @State private var notes: String = ""
    @State private var rating: Int = 0
    @State private var selectedBean: Bean? = nil
    @State private var selectedGrinder: Grinder? = nil
    @State private var selectedMachine: Machine? = nil
    @State private var selectedBrewer: Brewer? = nil
    // Picker selections use IDs to avoid Hashable/Equatable issues on models
    @State private var selectedBeanId: UUID? = nil
    @State private var selectedGrinderId: UUID? = nil
    @State private var selectedMachineId: UUID? = nil
    @State private var selectedBrewerId: UUID? = nil
    @State private var showingNewBean = false
    @State private var showingNewGrinder = false
    @State private var showingNewMachine = false
    @State private var showingNewBrewer = false
    @State private var isTiming = false
    @State private var timerStartDate: Date? = nil
    @State private var doseText: String = ""
    @State private var yieldText: String = ""
    @State private var bloomWaterGrams: Double = 0
    @State private var bloomTimeSeconds: Int = 0
    @State private var totalWaterGrams: Double = 0
    @State private var waterTemperatureCelsius: Double = 0
    @State private var bloomWaterText: String = ""
    @State private var totalWaterText: String = ""
    @State private var waterTempText: String = ""
    @State private var preInfusionTimeSeconds: Int = 0
    @State private var brewPressureBar: Double = 0
    @State private var brewPressureText: String = ""
    @State private var weatherSnapshot: WeatherSnapshot?
    
    private let manualDoseRange: ClosedRange<Double> = 5...30
    private let manualYieldRange: ClosedRange<Double> = 15...80
    private let bloomWaterRange: ClosedRange<Double> = 0...200
    private let totalWaterRange: ClosedRange<Double> = 0...1000
    private let waterTempRange: ClosedRange<Double> = 0...100
    
    var editingEntry: BrewEntry?
    
    init(editingEntry: BrewEntry? = nil) {
        self.editingEntry = editingEntry
        if let entry = editingEntry {
            _coffeeName = State(initialValue: entry.coffeeName)
            _grinderSetting = State(initialValue: entry.grinderSetting)
            _shotType = State(initialValue: entry.shotType)
            _doseGrams = State(initialValue: entry.doseGrams)
            _yieldGrams = State(initialValue: entry.yieldGrams)
            _brewTimeSeconds = State(initialValue: entry.brewTimeSeconds)
            _grinderTimerSeconds = State(initialValue: entry.grinderTimerSeconds)
            _brewStyle = State(initialValue: entry.brewStyle)
            _notes = State(initialValue: entry.notes ?? "")
            _rating = State(initialValue: entry.rating)
            _selectedBean = State(initialValue: entry.bean)
            _selectedGrinder = State(initialValue: entry.grinder)
            _selectedMachine = State(initialValue: entry.machine)
            _selectedBrewer = State(initialValue: entry.brewer)
            _selectedBeanId = State(initialValue: entry.bean?.id)
            _selectedGrinderId = State(initialValue: entry.grinder?.id)
            _selectedMachineId = State(initialValue: entry.machine?.id)
            _selectedBrewerId = State(initialValue: entry.brewer?.id)
            _bloomWaterGrams = State(initialValue: entry.bloomWaterGrams)
            _bloomTimeSeconds = State(initialValue: entry.bloomTimeSeconds)
            _totalWaterGrams = State(initialValue: entry.totalWaterInputGrams)
            _waterTemperatureCelsius = State(initialValue: entry.waterTemperatureCelsius)
            _preInfusionTimeSeconds = State(initialValue: entry.preInfusionTimeSeconds)
            _brewPressureBar = State(initialValue: entry.brewPressureBar)
            if entry.weatherTemperatureCelsius != nil || entry.weatherLocationName != nil {
                _weatherSnapshot = State(initialValue: WeatherSnapshot(
                    locationName: entry.weatherLocationName ?? "",
                    temperatureCelsius: entry.weatherTemperatureCelsius ?? 0,
                    humidityPercent: entry.weatherHumidityPercent ?? 0,
                    timestamp: entry.weatherCaptureDate ?? Date()
                ))
            }
        }
        _doseText = State(initialValue: Formatters.number.string(from: NSNumber(value: _doseGrams.wrappedValue)) ?? String(_doseGrams.wrappedValue))
        _yieldText = State(initialValue: Formatters.number.string(from: NSNumber(value: _yieldGrams.wrappedValue)) ?? String(_yieldGrams.wrappedValue))
        _bloomWaterText = State(initialValue: Formatters.number.string(from: NSNumber(value: _bloomWaterGrams.wrappedValue)) ?? String(_bloomWaterGrams.wrappedValue))
        _totalWaterText = State(initialValue: Formatters.number.string(from: NSNumber(value: _totalWaterGrams.wrappedValue)) ?? String(_totalWaterGrams.wrappedValue))
        _waterTempText = State(initialValue: Formatters.number.string(from: NSNumber(value: _waterTemperatureCelsius.wrappedValue)) ?? String(_waterTemperatureCelsius.wrappedValue))
        _brewPressureText = State(initialValue: Formatters.number.string(from: NSNumber(value: _brewPressureBar.wrappedValue)) ?? String(_brewPressureBar.wrappedValue))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Coffee".localized) {
                    TextField("Name".localized, text: $coffeeName)
                }
                Section("Style".localized) {
                    Picker("Brew Style".localized, selection: $brewStyle) {
                        Text("Espresso".localized).tag(BrewFlowType.espresso)
                        Text("Filter".localized).tag(BrewFlowType.filter)
                    }
                    .pickerStyle(.segmented)
                }
                if brewStyle == .espresso {
                    Section("Shot".localized) {
                        ShotTypePicker(shotType: $shotType)
                        Stepper(value: $preInfusionTimeSeconds, in: 0...30, step: 1) {
                            Text("Pre-infusion time".localized + ": \(preInfusionTimeSeconds) " + "s".localized)
                        }
                        HStack {
                            Text("Brew pressure".localized)
                            Spacer()
                            TextField("0.0", text: $brewPressureText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(minWidth: 60)
                                .onChange(of: brewPressureText) { _, new in
                                    if let val = parseDecimal(new) {
                                        brewPressureBar = min(max(val, 0), 12)
                                    }
                                }
                            Text("bar".localized).foregroundStyle(.secondary)
                        }
                        Stepper(value: $brewPressureBar, in: 0...12, step: 0.1) {
                            Text(String(format: "%.1f %@", brewPressureBar, "bar".localized))
                        }
                        .onChange(of: brewPressureBar) { _, new in
                            brewPressureText = Formatters.number.string(from: NSNumber(value: new)) ?? String(new)
                        }
                    }
                }
                Section("Grinder".localized) {
                    Stepper(value: $grinderSetting, in: 0...20, step: 0.1) {
                        Text("Grinder setting".localized + ": \(Formatters.number.string(from: NSNumber(value: grinderSetting)) ?? String(grinderSetting))")
                    }
                    Stepper(value: $grinderTimerSeconds, in: 0...60, step: 0.1) {
                        Text("Grinder timer".localized + ": \(Formatters.number.string(from: NSNumber(value: grinderTimerSeconds)) ?? String(format: "%.1f", grinderTimerSeconds)) " + "s".localized)
                    }
                }
                Section("Gear".localized) {
                    Picker("Bean".localized, selection: $selectedBeanId) {
                        Text("None".localized).tag(nil as UUID?)
                        ForEach(beans) { bean in
                            Text(bean.name).tag(Optional(bean.id))
                        }
                    }
                    .onChange(of: selectedBeanId) { _, newId in
                        selectedBean = beans.first(where: { $0.id == newId })
                    }
                    Button {
                        showingNewBean = true
                    } label: {
                        Label("Add new bean".localized, systemImage: "plus.circle")
                    }
                    
                    Picker("Grinder".localized, selection: $selectedGrinderId) {
                        Text("None".localized).tag(nil as UUID?)
                        ForEach(grinders) { grinder in
                            Text(grinder.name).tag(Optional(grinder.id))
                        }
                    }
                    .onChange(of: selectedGrinderId) { _, newId in
                        selectedGrinder = grinders.first(where: { $0.id == newId })
                    }
                    Button {
                        showingNewGrinder = true
                    } label: {
                        Label("Add new grinder".localized, systemImage: "plus.circle")
                    }
                    
                    if brewStyle == .espresso {
                        Picker("Machine".localized, selection: $selectedMachineId) {
                            Text("None".localized).tag(nil as UUID?)
                            ForEach(machines) { machine in
                                Text(machine.name).tag(Optional(machine.id))
                            }
                        }
                        .onChange(of: selectedMachineId) { _, newId in
                            selectedMachine = machines.first(where: { $0.id == newId })
                        }
                        Button {
                            showingNewMachine = true
                        } label: {
                            Label("Add new machine".localized, systemImage: "plus.circle")
                        }
                    } else {
                        Picker("Brewer".localized, selection: $selectedBrewerId) {
                            Text("None".localized).tag(nil as UUID?)
                            ForEach(brewers) { brewer in
                                Text(brewer.name).tag(Optional(brewer.id))
                            }
                        }
                        .onChange(of: selectedBrewerId) { _, newId in
                            selectedBrewer = brewers.first(where: { $0.id == newId })
                        }
                        Button {
                            showingNewBrewer = true
                        } label: {
                            Label("Add new brewer".localized, systemImage: "plus.circle")
                        }
                    }
                }
                
                if brewStyle == .filter {
                    Section("Bloom".localized) {
                        HStack {
                            Text("Bloom water".localized)
                            Spacer()
                            TextField("0.0", text: $bloomWaterText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(minWidth: 60)
                                .onChange(of: bloomWaterText) { _, new in
                                    if let val = parseDecimal(new) {
                                        bloomWaterGrams = min(max(val, bloomWaterRange.lowerBound), bloomWaterRange.upperBound)
                                    }
                                }
                            Text("g".localized).foregroundStyle(.secondary)
                        }
                        Stepper(value: $bloomTimeSeconds, in: 0...120, step: 1) {
                            Text("Bloom time".localized + ": \(bloomTimeSeconds) " + "s".localized)
                        }
                    }
                    
                    Section("Water".localized) {
                        HStack {
                            Text("Total water".localized)
                            Spacer()
                            TextField("0.0", text: $totalWaterText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(minWidth: 60)
                                .onChange(of: totalWaterText) { _, new in
                                    if let val = parseDecimal(new) {
                                        totalWaterGrams = min(max(val, totalWaterRange.lowerBound), totalWaterRange.upperBound)
                                    }
                                }
                            Text("g".localized).foregroundStyle(.secondary)
                        }
                        HStack {
                            Text("Water temp".localized)
                            Spacer()
                            TextField("0.0", text: $waterTempText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(minWidth: 60)
                                .onChange(of: waterTempText) { _, new in
                                    if let val = parseDecimal(new) {
                                        waterTemperatureCelsius = min(max(val, waterTempRange.lowerBound), waterTempRange.upperBound)
                                    }
                                }
                            Text("°C".localized).foregroundStyle(.secondary)
                        }
                    }
                }
                Section("Brew".localized) {
                    HStack {
                        Text("Dose".localized)
                        Spacer()
                        TextField("0.0", text: $doseText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(minWidth: 60)
                            .onChange(of: doseText) { _, new in
                                if let val = parseDecimal(new) {
                                    doseGrams = min(max(val, manualDoseRange.lowerBound), manualDoseRange.upperBound)
                                }
                            }
                        Text("g".localized).foregroundStyle(.secondary)
                        Stepper("", value: $doseGrams, in: manualDoseRange, step: 0.1)
                            .labelsHidden()
                            .onChange(of: doseGrams) { _, new in
                                doseText = Formatters.number.string(from: NSNumber(value: new)) ?? String(new)
                            }
                    }
                    HStack {
                        Text("Yield".localized)
                        Spacer()
                        TextField("0.0", text: $yieldText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(minWidth: 60)
                            .onChange(of: yieldText) { _, new in
                                if let val = parseDecimal(new) {
                                    yieldGrams = min(max(val, manualYieldRange.lowerBound), manualYieldRange.upperBound)
                                }
                            }
                        Text("g".localized).foregroundStyle(.secondary)
                        Stepper("", value: $yieldGrams, in: manualYieldRange, step: 0.1)
                            .labelsHidden()
                            .onChange(of: yieldGrams) { _, new in
                                yieldText = Formatters.number.string(from: NSNumber(value: new)) ?? String(new)
                            }
                    }
                    Group {
                        if isTiming {
                            TimelineView(.periodic(from: Date(), by: 1)) { context in
                                brewTimerLabel(contextDate: context.date)
                            }
                        } else {
                            brewTimerLabel(contextDate: Date())
                        }
                    }
                    HStack {
                        Button {
                            toggleTimer()
                        } label: {
                            Label(isTiming ? "Stop".localized : "Start".localized, systemImage: isTiming ? "stop.fill" : "play.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(isTiming ? .red : AppTheme.accent)
                        Button("Reset".localized) {
                            resetTimer()
                        }
                        .buttonStyle(.bordered)
                        .disabled(isTiming == false && brewTimeSeconds == 0)
                    }
                    HStack {
                        Text("Brew Ratio".localized)
                        Spacer()
                        Text(Formatters.ratioString(dose: doseGrams, yield: yieldGrams))
                            .foregroundStyle(.secondary)
                    }
                }
                Section("Rating".localized) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Rate this brew".localized)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                        StarRatingView(rating: $rating, editable: true, size: 32)
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Notes".localized) {
                    TextField("Optional notes".localized, text: $notes, axis: .vertical)
                }

                WeatherCaptureSection(snapshot: $weatherSnapshot)
            }
            .navigationTitle(editingEntry == nil ? "New Brew".localized : "Edit Brew".localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save".localized) { save() }
                        .disabled(coffeeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || doseGrams <= 0)
                }
            }
            .onAppear {
                clampManualRanges()
            }
            .onChange(of: brewStyle) { _, newStyle in
                if newStyle == .espresso {
                    selectedBrewer = nil
                    selectedBrewerId = nil
                    bloomWaterGrams = 0
                    bloomTimeSeconds = 0
                    totalWaterGrams = 0
                    waterTemperatureCelsius = 0
                    bloomWaterText = Formatters.number.string(from: NSNumber(value: bloomWaterGrams)) ?? "0"
                    totalWaterText = Formatters.number.string(from: NSNumber(value: totalWaterGrams)) ?? "0"
                    waterTempText = Formatters.number.string(from: NSNumber(value: waterTemperatureCelsius)) ?? "0"
                } else {
                    selectedMachine = nil
                    selectedMachineId = nil
                    preInfusionTimeSeconds = 0
                    brewPressureBar = 0
                    brewPressureText = "0"
                }
            }
            .onDisappear {
                // If timing when leaving, persist elapsed so far
                if isTiming, let start = timerStartDate {
                    brewTimeSeconds = max(0, Int(Date().timeIntervalSince(start).rounded()))
                    isTiming = false
                }
            }
            .sheet(isPresented: $showingNewBean) {
                BeanFormView { newBean in
                    modelContext.insert(newBean)
                    ErrorHandler.save(modelContext, errorMessage: "Failed to save bean. Please try again.".localized) {
                    selectedBean = newBean
                    selectedBeanId = newBean.id
                    }
                }
            }
            .sheet(isPresented: $showingNewGrinder) {
                GrinderFormView { newGrinder in
                    modelContext.insert(newGrinder)
                    ErrorHandler.save(modelContext, errorMessage: "Failed to save grinder. Please try again.".localized) {
                    selectedGrinder = newGrinder
                    selectedGrinderId = newGrinder.id
                    }
                }
            }
            .sheet(isPresented: $showingNewMachine) {
                MachineFormView { newMachine in
                    modelContext.insert(newMachine)
                    ErrorHandler.save(modelContext, errorMessage: "Failed to save machine. Please try again.".localized) {
                    selectedMachine = newMachine
                    selectedMachineId = newMachine.id
                    }
                }
            }
            .sheet(isPresented: $showingNewBrewer) {
                BrewerFormView { newBrewer in
                    modelContext.insert(newBrewer)
                    ErrorHandler.save(modelContext, errorMessage: "Failed to save brewer. Please try again.".localized) {
                    selectedBrewer = newBrewer
                    selectedBrewerId = newBrewer.id
                }
            }
            }
            .errorAlert()
        }
    }
    
    private func toggleTimer() {
        if isTiming {
            if let start = timerStartDate {
                brewTimeSeconds = max(0, Int(Date().timeIntervalSince(start).rounded()))
            }
            isTiming = false
            timerStartDate = nil
            HapticFeedback.light()
        } else {
            isTiming = true
            timerStartDate = Date()
            HapticFeedback.light()
        }
    }

    @ViewBuilder
    private func brewTimerLabel(contextDate: Date) -> some View {
        let displayed: String = {
            if isTiming, let start = timerStartDate {
                let elapsed = max(0, Int(contextDate.timeIntervalSince(start).rounded()))
                return Formatters.secondsString(elapsed)
            }
            return Formatters.secondsString(brewTimeSeconds)
        }()
        HStack {
            Text(brewStyle == .espresso ? "Shot Time".localized : "Brew Time".localized)
            Spacer()
            Text(displayed)
                .font(.largeTitle.weight(.bold).monospacedDigit())
                .monospacedDigit()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(colors: [AppTheme.accentSecondary.opacity(0.18), AppTheme.cardBackground],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
        )
    }
    
    private func resetTimer() {
        brewTimeSeconds = 0
        isTiming = false
        timerStartDate = nil
    }
    
    private func parseDecimal(_ text: String) -> Double? {
        let normalized = text.replacingOccurrences(of: ",", with: ".")
        return Formatters.number.number(from: normalized)?.doubleValue
    }
    
    private func clampManualRanges() {
        doseGrams = min(max(doseGrams, manualDoseRange.lowerBound), manualDoseRange.upperBound)
        yieldGrams = min(max(yieldGrams, manualYieldRange.lowerBound), manualYieldRange.upperBound)
        grinderTimerSeconds = min(max(grinderTimerSeconds, 0), 60)
        doseText = Formatters.number.string(from: NSNumber(value: doseGrams)) ?? String(doseGrams)
        yieldText = Formatters.number.string(from: NSNumber(value: yieldGrams)) ?? String(yieldGrams)
        bloomWaterGrams = min(max(bloomWaterGrams, bloomWaterRange.lowerBound), bloomWaterRange.upperBound)
        bloomWaterText = Formatters.number.string(from: NSNumber(value: bloomWaterGrams)) ?? String(bloomWaterGrams)
        totalWaterGrams = min(max(totalWaterGrams, totalWaterRange.lowerBound), totalWaterRange.upperBound)
        totalWaterText = Formatters.number.string(from: NSNumber(value: totalWaterGrams)) ?? String(totalWaterGrams)
        waterTemperatureCelsius = min(max(waterTemperatureCelsius, waterTempRange.lowerBound), waterTempRange.upperBound)
        waterTempText = Formatters.number.string(from: NSNumber(value: waterTemperatureCelsius)) ?? String(waterTemperatureCelsius)
        bloomTimeSeconds = min(max(bloomTimeSeconds, 0), 120)
        preInfusionTimeSeconds = min(max(preInfusionTimeSeconds, 0), 30)
        brewPressureBar = min(max(brewPressureBar, 0), 12)
        brewPressureText = Formatters.number.string(from: NSNumber(value: brewPressureBar)) ?? String(brewPressureBar)
    }
    
    private func save() {
        if let entry = editingEntry {
            entry.coffeeName = coffeeName
            entry.grinderSetting = grinderSetting
            entry.shotType = shotType
            entry.doseGrams = doseGrams
            entry.yieldGrams = yieldGrams
            entry.brewTimeSeconds = brewTimeSeconds
            entry.rating = rating
            entry.grinderTimerSeconds = grinderTimerSeconds
            entry.brewStyle = brewStyle
            entry.notes = notes.isEmpty ? nil : notes
            entry.bean = selectedBean
            entry.grinder = selectedGrinder
            entry.machine = brewStyle == .espresso ? selectedMachine : nil
            entry.brewer = brewStyle == .filter ? selectedBrewer : nil
            entry.bloomWaterGrams = brewStyle == .filter ? bloomWaterGrams : 0
            entry.bloomTimeSeconds = brewStyle == .filter ? bloomTimeSeconds : 0
            entry.totalWaterInputGrams = brewStyle == .filter ? totalWaterGrams : 0
            entry.waterTemperatureCelsius = brewStyle == .filter ? waterTemperatureCelsius : 0
            entry.preInfusionTimeSeconds = brewStyle == .espresso ? preInfusionTimeSeconds : 0
            entry.brewPressureBar = brewStyle == .espresso ? brewPressureBar : 0
            entry.weatherTemperatureCelsius = weatherSnapshot?.temperatureCelsius
            entry.weatherHumidityPercent = weatherSnapshot?.humidityPercent
            entry.weatherLocationName = weatherSnapshot?.locationName
            entry.weatherCaptureDate = weatherSnapshot?.timestamp
        } else {
            let newEntry = BrewEntry(
                coffeeName: coffeeName,
                grinderSetting: grinderSetting,
                shotType: shotType,
                doseGrams: doseGrams,
                yieldGrams: yieldGrams,
                brewTimeSeconds: brewTimeSeconds,
                grinderTimerSeconds: grinderTimerSeconds,
                bloomWaterGrams: brewStyle == .filter ? bloomWaterGrams : 0,
                bloomTimeSeconds: brewStyle == .filter ? bloomTimeSeconds : 0,
                totalWaterInputGrams: brewStyle == .filter ? totalWaterGrams : 0,
                waterTemperatureCelsius: brewStyle == .filter ? waterTemperatureCelsius : 0,
                preInfusionTimeSeconds: brewStyle == .espresso ? preInfusionTimeSeconds : 0,
                brewPressureBar: brewStyle == .espresso ? brewPressureBar : 0,
                brewStyle: brewStyle,
                rating: rating,
                weatherTemperatureCelsius: weatherSnapshot?.temperatureCelsius,
                weatherHumidityPercent: weatherSnapshot?.humidityPercent,
                weatherLocationName: weatherSnapshot?.locationName,
                weatherCaptureDate: weatherSnapshot?.timestamp,
                notes: notes.isEmpty ? nil : notes,
                bean: selectedBean,
                grinder: selectedGrinder,
                machine: brewStyle == .espresso ? selectedMachine : nil,
                brewer: brewStyle == .filter ? selectedBrewer : nil
            )
            modelContext.insert(newEntry)
        }
        ErrorHandler.save(modelContext, errorMessage: "Failed to save brew entry. Please try again.".localized) {
        dismiss()
        }
    }
}

struct BrewFormView_Previews: PreviewProvider {
    static var previews: some View {
        BrewFormView()
    }
}


