import Foundation
import SwiftData

enum ShotType: Int, Codable, CaseIterable, Identifiable, Sendable {
    case single = 1
    case double = 2
    case triple = 3
    
    var id: Int { rawValue }
    
    var displayName: String {
        switch self {
        case .single: return "Single".localized
        case .double: return "Double".localized
        case .triple: return "Triple".localized
        }
    }
}

@Model
final class BrewEntry {
    // CloudKit: avoid unique constraints and provide defaults
    var id: UUID = UUID()
    var createdAt: Date = Date()
    
    var coffeeName: String = ""
    var grinderSetting: Double = 0
    var shotType: ShotType = ShotType.double
    
    var doseGrams: Double = 0
    var yieldGrams: Double = 0
    var brewTimeSeconds: Int = 0
    var grinderTimerSeconds: Double = 0
    var bloomWaterGrams: Double = 0
    var bloomTimeSeconds: Int = 0
    var totalWaterInputGrams: Double = 0
    var waterTemperatureCelsius: Double = 0
    var preInfusionTimeSeconds: Int = 0
    var brewPressureBar: Double = 0
    var isFavorite: Bool = false
    var rating: Int = 0 // 0-5 stars
    var brewStyleRaw: String = BrewFlowType.espresso.rawValue
    var weatherTemperatureCelsius: Double?
    var weatherHumidityPercent: Double?
    var weatherLocationName: String?
    var weatherCaptureDate: Date?
    
    // Optional: keep raw timer display text if desired
    var timerRaw: String?
    var notes: String?
    
    // Relationships (optional, can be nil)
    @Relationship var bean: Bean?
    @Relationship var grinder: Grinder?
    @Relationship var machine: Machine?
    @Relationship var brewer: Brewer?
    
    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        coffeeName: String,
        grinderSetting: Double,
        shotType: ShotType,
        doseGrams: Double,
        yieldGrams: Double,
        brewTimeSeconds: Int,
        grinderTimerSeconds: Double = 0,
        bloomWaterGrams: Double = 0,
        bloomTimeSeconds: Int = 0,
        totalWaterInputGrams: Double = 0,
        waterTemperatureCelsius: Double = 0,
        preInfusionTimeSeconds: Int = 0,
        brewPressureBar: Double = 0,
        brewStyle: BrewFlowType = .espresso,
        isFavorite: Bool = false,
        rating: Int = 0,
        timerRaw: String? = nil,
        weatherTemperatureCelsius: Double? = nil,
        weatherHumidityPercent: Double? = nil,
        weatherLocationName: String? = nil,
        weatherCaptureDate: Date? = nil,
        notes: String? = nil,
        bean: Bean? = nil,
        grinder: Grinder? = nil,
        machine: Machine? = nil,
        brewer: Brewer? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.coffeeName = coffeeName
        self.grinderSetting = grinderSetting
        self.shotType = shotType
        self.doseGrams = doseGrams
        self.yieldGrams = yieldGrams
        self.brewTimeSeconds = brewTimeSeconds
        self.grinderTimerSeconds = grinderTimerSeconds
        self.bloomWaterGrams = bloomWaterGrams
        self.bloomTimeSeconds = bloomTimeSeconds
        self.totalWaterInputGrams = totalWaterInputGrams
        self.waterTemperatureCelsius = waterTemperatureCelsius
        self.preInfusionTimeSeconds = preInfusionTimeSeconds
        self.brewPressureBar = brewPressureBar
        self.isFavorite = isFavorite
        self.rating = rating
        self.brewStyleRaw = brewStyle.rawValue
        self.timerRaw = timerRaw
        self.weatherTemperatureCelsius = weatherTemperatureCelsius
        self.weatherHumidityPercent = weatherHumidityPercent
        self.weatherLocationName = weatherLocationName
        self.weatherCaptureDate = weatherCaptureDate
        self.notes = notes
        self.bean = bean
        self.grinder = grinder
        self.machine = machine
        self.brewer = brewer
    }
}

extension BrewEntry {
    var brewStyle: BrewFlowType {
        get { BrewFlowType(rawValue: brewStyleRaw) ?? .espresso }
        set { brewStyleRaw = newValue.rawValue }
    }

    var brewRatio: Double {
        guard doseGrams > 0 else { return 0 }
        return yieldGrams / doseGrams
    }

    /// Title stored on the brew: selected bean name, or the brew style if no bean is set.
    static func generatedCoffeeName(bean: Bean?, style: BrewFlowType) -> String {
        let beanName = bean?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !beanName.isEmpty { return beanName }
        return style.title
    }

    static func duplicate(from entry: BrewEntry) -> BrewEntry {
        BrewEntry(
            coffeeName: entry.coffeeName,
            grinderSetting: entry.grinderSetting,
            shotType: entry.shotType,
            doseGrams: entry.doseGrams,
            yieldGrams: entry.yieldGrams,
            brewTimeSeconds: entry.brewTimeSeconds,
            grinderTimerSeconds: entry.grinderTimerSeconds,
            bloomWaterGrams: entry.bloomWaterGrams,
            bloomTimeSeconds: entry.bloomTimeSeconds,
            totalWaterInputGrams: entry.totalWaterInputGrams,
            waterTemperatureCelsius: entry.waterTemperatureCelsius,
            preInfusionTimeSeconds: entry.preInfusionTimeSeconds,
            brewPressureBar: entry.brewPressureBar,
            brewStyle: entry.brewStyle,
            isFavorite: entry.isFavorite,
            rating: entry.rating,
            weatherTemperatureCelsius: entry.weatherTemperatureCelsius,
            weatherHumidityPercent: entry.weatherHumidityPercent,
            weatherLocationName: entry.weatherLocationName,
            weatherCaptureDate: entry.weatherCaptureDate,
            notes: entry.notes,
            bean: entry.bean,
            grinder: entry.grinder,
            machine: entry.machine,
            brewer: entry.brewer
        )
    }
}

extension Bean {
    var daysSinceRoast: Int? {
        guard let roastDate else { return nil }
        return Calendar.current.dateComponents([.day], from: roastDate, to: Date()).day
    }

    var isPastPeak: Bool {
        guard let days = daysSinceRoast else { return false }
        return days > 28
    }

    var displayPhotoData: Data? {
        if let photoData { return photoData }
        return PhotoStorage.loadPhoto(path: photoPath)
    }
}

extension Grinder {
    var displayPhotoData: Data? {
        if let photoData { return photoData }
        return PhotoStorage.loadPhoto(path: photoPath)
    }
}

extension Machine {
    var displayPhotoData: Data? {
        if let photoData { return photoData }
        return PhotoStorage.loadPhoto(path: photoPath)
    }
}

extension Brewer {
    var displayPhotoData: Data? {
        if let photoData { return photoData }
        return PhotoStorage.loadPhoto(path: photoPath)
    }
}


