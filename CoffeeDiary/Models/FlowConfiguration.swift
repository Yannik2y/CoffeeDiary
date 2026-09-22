import Foundation

struct FlowConfiguration: Codable, Equatable {
    var espressoCoffee = true
    var espressoShotType = true
    var espressoGrinder = true
    var espressoGrinderTimer = true
    var espressoDose = true
    var espressoTime = true
    var espressoPreInfusionTime = true
    var espressoBrewPressure = true
    var espressoYield = true
    var espressoGear = true
    var espressoNotes = true
    var espressoRating = true
    var espressoWeather = true

    var filterCoffee = true
    var filterGrinder = true
    var filterGrinderTimer = true
    var filterDose = true
    var filterTime = true
    var filterYield = true
    var filterGear = true
    var filterNotes = true
    var filterBrewer = true
    var filterBloom = true
    var filterTotalWater = true
    var filterWaterTemp = true
    var filterRating = true
    var filterWeather = true

    private static let storageKey = "flowConfiguration"

    static func load() -> FlowConfiguration {
        // Prefer iCloud KVS so flow prefs follow the user across devices, then fall back to UserDefaults.
        if let data = NSUbiquitousKeyValueStore.default.data(forKey: storageKey),
           let config = try? JSONDecoder().decode(FlowConfiguration.self, from: data) {
            return config
        }
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let config = try? JSONDecoder().decode(FlowConfiguration.self, from: data) else {
            return FlowConfiguration()
        }
        return config
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
        NSUbiquitousKeyValueStore.default.set(data, forKey: Self.storageKey)
        NSUbiquitousKeyValueStore.default.synchronize()
    }

    func isEnabled(_ step: FlowStep, for flow: BrewFlowType) -> Bool {
        switch (flow, step) {
        case (.espresso, .coffee): return espressoCoffee
        case (.espresso, .shotType): return espressoShotType
        case (.espresso, .grinder): return espressoGrinder
        case (.espresso, .grinderTimer): return espressoGrinderTimer
        case (.espresso, .dose): return espressoDose
        case (.espresso, .time): return espressoTime
        case (.espresso, .preInfusionTime): return espressoPreInfusionTime
        case (.espresso, .brewPressure): return espressoBrewPressure
        case (.espresso, .yield): return espressoYield
        case (.espresso, .gear): return true
        case (.espresso, .notes): return espressoNotes
        case (.espresso, .rating): return espressoRating
        case (.espresso, .weather): return espressoWeather
        case (.filter, .coffee): return filterCoffee
        case (.filter, .grinder): return filterGrinder
        case (.filter, .grinderTimer): return filterGrinderTimer
        case (.filter, .dose): return filterDose
        case (.filter, .time): return filterTime
        case (.filter, .yield): return filterYield
        case (.filter, .gear): return true
        case (.filter, .notes): return filterNotes
        case (.filter, .brewer): return true
        case (.filter, .bloom): return filterBloom
        case (.filter, .totalWater): return filterTotalWater
        case (.filter, .waterTemp): return filterWaterTemp
        case (.filter, .rating): return filterRating
        case (.filter, .weather): return filterWeather
        default: return true
        }
    }

    func binding(for step: FlowStep, flow: BrewFlowType) -> WritableKeyPath<FlowConfiguration, Bool>? {
        switch (flow, step) {
        case (.espresso, .coffee): return \.espressoCoffee
        case (.espresso, .shotType): return \.espressoShotType
        case (.espresso, .grinder): return \.espressoGrinder
        case (.espresso, .grinderTimer): return \.espressoGrinderTimer
        case (.espresso, .dose): return \.espressoDose
        case (.espresso, .time): return \.espressoTime
        case (.espresso, .preInfusionTime): return \.espressoPreInfusionTime
        case (.espresso, .brewPressure): return \.espressoBrewPressure
        case (.espresso, .yield): return \.espressoYield
        case (.espresso, .gear): return \.espressoGear
        case (.espresso, .notes): return \.espressoNotes
        case (.espresso, .rating): return \.espressoRating
        case (.espresso, .weather): return \.espressoWeather
        case (.filter, .coffee): return \.filterCoffee
        case (.filter, .grinder): return \.filterGrinder
        case (.filter, .grinderTimer): return \.filterGrinderTimer
        case (.filter, .dose): return \.filterDose
        case (.filter, .time): return \.filterTime
        case (.filter, .yield): return \.filterYield
        case (.filter, .gear): return \.filterGear
        case (.filter, .notes): return \.filterNotes
        case (.filter, .brewer): return \.filterBrewer
        case (.filter, .bloom): return \.filterBloom
        case (.filter, .totalWater): return \.filterTotalWater
        case (.filter, .waterTemp): return \.filterWaterTemp
        case (.filter, .rating): return \.filterRating
        case (.filter, .weather): return \.filterWeather
        default: return nil
        }
    }
}

enum FlowStep: String, CaseIterable {
    case coffee, shotType, grinder, grinderTimer, dose, time, preInfusionTime
    case brewPressure, yield, gear, brewer, bloom, totalWater, waterTemp
    case notes, rating, weather, review

    var title: String {
        switch self {
        case .coffee: return "Coffee Name".localized
        case .shotType: return "Shot Type".localized
        case .grinder: return "Grinder Setting".localized
        case .grinderTimer: return "Grinder Timer".localized
        case .dose: return "Dose".localized
        case .time: return "Brew time".localized
        case .preInfusionTime: return "Pre-infusion time".localized
        case .brewPressure: return "Brew pressure".localized
        case .yield: return "Brewed Amount".localized
        case .gear: return "Equipment (Bean/Grinder/Machine)".localized
        case .brewer: return "Brewer Selection".localized
        case .bloom: return "Bloom Details".localized
        case .totalWater: return "Total Water".localized
        case .waterTemp: return "Water Temperature".localized
        case .notes: return "Notes".localized
        case .rating: return "Rating".localized
        case .weather: return "Weather".localized
        case .review: return "Review".localized
        }
    }
}
