import Foundation
import SwiftData

/// Fixed demo content for App Store screenshots (`--snapshot` launch argument).
enum SnapshotDemoData {
    static let featuredBrewID = UUID(uuidString: "A1111111-1111-1111-1111-111111111111")!

    static func seedIfNeeded(context: ModelContext) {
        let existing = try? context.fetch(FetchDescriptor<BrewEntry>())
        guard existing?.isEmpty != false else { return }

        let calendar = Calendar.current
        let now = Date()

        let machine = Machine(
            id: UUID(uuidString: "B2222222-2222-2222-2222-222222222222")!,
            name: "Linea Mini",
            brand: "La Marzocco",
            model: "Linea Mini",
            notes: "Wohnküche",
            isActive: true,
            brandId: nil,
            modelId: nil,
            silhouetteId: EquipmentSilhouette.machineE61.rawValue
        )

        let grinder = Grinder(
            id: UUID(uuidString: "C3333333-3333-3333-3333-333333333333")!,
            name: "Niche Zero",
            brand: "Niche",
            burrType: "Konisch",
            notes: "Single Dose",
            defaultSetting: 18.5,
            isActive: true,
            brandId: nil,
            model: "Zero",
            modelId: nil,
            silhouetteId: EquipmentSilhouette.grinderSingleDose.rawValue
        )

        let brewer = Brewer(
            id: UUID(uuidString: "D4444444-4444-4444-4444-444444444444")!,
            name: "V60",
            brand: "Hario",
            style: "Pour Over",
            notes: "Größe 02",
            isFavorite: true
        )

        let ethiopian = Bean(
            id: UUID(uuidString: "E5555555-5555-5555-5555-555555555555")!,
            name: "Yirgacheffe",
            roaster: "Five Elephant",
            origin: "Äthiopien",
            process: "Washed",
            variety: "Heirloom",
            roastDate: calendar.date(byAdding: .day, value: -8, to: now),
            notes: "Jasmin, Bergamotte",
            isFavorite: true,
            arabicaPercentage: 100,
            robustaPercentage: 0
        )

        let brazilian = Bean(
            id: UUID(uuidString: "F6666666-6666-6666-6666-666666666666")!,
            name: "Cerrado",
            roaster: "The Barn",
            origin: "Brasilien",
            process: "Natural",
            variety: "Bourbon",
            roastDate: calendar.date(byAdding: .day, value: -14, to: now),
            notes: "Schokolade, Nuss",
            isFavorite: false,
            arabicaPercentage: 100,
            robustaPercentage: 0
        )

        context.insert(machine)
        context.insert(grinder)
        context.insert(brewer)
        context.insert(ethiopian)
        context.insert(brazilian)

        struct BrewSpec {
            let id: UUID?
            let daysAgo: Int
            let hours: Int
            let bean: Bean
            let style: BrewFlowType
            let shot: ShotType
            let dose: Double
            let yield: Double
            let time: Int
            let grind: Double
            let rating: Int
            let favorite: Bool
            let notes: String?
            let pressure: Double
            let preInfusion: Int
            let bloomWater: Double
            let bloomTime: Int
            let totalWater: Double
            let waterTemp: Double
            let weatherTemp: Double?
            let weatherHumidity: Double?
        }

        let specs: [BrewSpec] = [
            BrewSpec(
                id: featuredBrewID, daysAgo: 0, hours: -2, bean: ethiopian, style: .espresso, shot: .double,
                dose: 18.0, yield: 36.0, time: 28, grind: 18.5, rating: 5, favorite: true,
                notes: "Süße klar, Balance stimmt.", pressure: 9.0, preInfusion: 4,
                bloomWater: 0, bloomTime: 0, totalWater: 0, waterTemp: 0,
                weatherTemp: 21.0, weatherHumidity: 48.0
            ),
            BrewSpec(
                id: nil, daysAgo: 1, hours: -9, bean: ethiopian, style: .espresso, shot: .double,
                dose: 18.0, yield: 37.0, time: 26, grind: 18.5, rating: 4, favorite: false,
                notes: "Etwas dünn am Ende.", pressure: 9.0, preInfusion: 4,
                bloomWater: 0, bloomTime: 0, totalWater: 0, waterTemp: 0,
                weatherTemp: 19.5, weatherHumidity: 55.0
            ),
            BrewSpec(
                id: nil, daysAgo: 2, hours: -10, bean: ethiopian, style: .espresso, shot: .double,
                dose: 18.0, yield: 35.0, time: 30, grind: 18.0, rating: 4, favorite: false,
                notes: nil, pressure: 9.0, preInfusion: 5,
                bloomWater: 0, bloomTime: 0, totalWater: 0, waterTemp: 0,
                weatherTemp: nil, weatherHumidity: nil
            ),
            BrewSpec(
                id: nil, daysAgo: 3, hours: -8, bean: ethiopian, style: .espresso, shot: .double,
                dose: 18.0, yield: 36.0, time: 29, grind: 18.5, rating: 5, favorite: false,
                notes: "Referenz-Shot.", pressure: 9.0, preInfusion: 4,
                bloomWater: 0, bloomTime: 0, totalWater: 0, waterTemp: 0,
                weatherTemp: 22.0, weatherHumidity: 42.0
            ),
            BrewSpec(
                id: nil, daysAgo: 4, hours: -11, bean: brazilian, style: .espresso, shot: .double,
                dose: 18.5, yield: 38.0, time: 27, grind: 19.0, rating: 3, favorite: false,
                notes: "Zu bitter — feiner mahlen.", pressure: 9.0, preInfusion: 3,
                bloomWater: 0, bloomTime: 0, totalWater: 0, waterTemp: 0,
                weatherTemp: nil, weatherHumidity: nil
            ),
            BrewSpec(
                id: nil, daysAgo: 5, hours: -9, bean: ethiopian, style: .filter, shot: .double,
                dose: 15.0, yield: 250.0, time: 195, grind: 42.0, rating: 5, favorite: true,
                notes: "Blumig, klar.", pressure: 0, preInfusion: 0,
                bloomWater: 45, bloomTime: 40, totalWater: 250, waterTemp: 93,
                weatherTemp: 18.0, weatherHumidity: 60.0
            ),
            BrewSpec(
                id: nil, daysAgo: 7, hours: -10, bean: brazilian, style: .filter, shot: .double,
                dose: 16.0, yield: 260.0, time: 210, grind: 44.0, rating: 4, favorite: false,
                notes: nil, pressure: 0, preInfusion: 0,
                bloomWater: 50, bloomTime: 45, totalWater: 260, waterTemp: 92,
                weatherTemp: nil, weatherHumidity: nil
            ),
            BrewSpec(
                id: nil, daysAgo: 9, hours: -8, bean: ethiopian, style: .espresso, shot: .single,
                dose: 9.0, yield: 20.0, time: 24, grind: 16.5, rating: 4, favorite: false,
                notes: nil, pressure: 9.0, preInfusion: 3,
                bloomWater: 0, bloomTime: 0, totalWater: 0, waterTemp: 0,
                weatherTemp: 20.0, weatherHumidity: 50.0
            ),
            BrewSpec(
                id: nil, daysAgo: 12, hours: -12, bean: brazilian, style: .espresso, shot: .double,
                dose: 18.0, yield: 36.0, time: 28, grind: 18.0, rating: 4, favorite: false,
                notes: "Schokolade kommt durch.", pressure: 9.0, preInfusion: 4,
                bloomWater: 0, bloomTime: 0, totalWater: 0, waterTemp: 0,
                weatherTemp: nil, weatherHumidity: nil
            ),
            BrewSpec(
                id: nil, daysAgo: 14, hours: -9, bean: ethiopian, style: .filter, shot: .double,
                dose: 15.0, yield: 240.0, time: 185, grind: 41.0, rating: 3, favorite: false,
                notes: "Etwas unterextrahiert.", pressure: 0, preInfusion: 0,
                bloomWater: 40, bloomTime: 35, totalWater: 240, waterTemp: 94,
                weatherTemp: 17.0, weatherHumidity: 65.0
            )
        ]

        for spec in specs {
            var created = calendar.date(byAdding: .day, value: -spec.daysAgo, to: now) ?? now
            created = calendar.date(byAdding: .hour, value: spec.hours, to: created) ?? created

            let coffeeName = BrewEntry.generatedCoffeeName(bean: spec.bean, style: spec.style)
            let entry = BrewEntry(
                id: spec.id ?? UUID(),
                createdAt: created,
                coffeeName: coffeeName,
                grinderSetting: spec.grind,
                shotType: spec.shot,
                doseGrams: spec.dose,
                yieldGrams: spec.yield,
                brewTimeSeconds: spec.time,
                bloomWaterGrams: spec.bloomWater,
                bloomTimeSeconds: spec.bloomTime,
                totalWaterInputGrams: spec.totalWater,
                waterTemperatureCelsius: spec.waterTemp,
                preInfusionTimeSeconds: spec.preInfusion,
                brewPressureBar: spec.pressure,
                brewStyle: spec.style,
                isFavorite: spec.favorite,
                rating: spec.rating,
                weatherTemperatureCelsius: spec.weatherTemp,
                weatherHumidityPercent: spec.weatherHumidity,
                weatherLocationName: spec.weatherTemp == nil ? nil : "Berlin",
                weatherCaptureDate: spec.weatherTemp == nil ? nil : created,
                notes: spec.notes,
                bean: spec.bean,
                grinder: grinder,
                machine: spec.style == .espresso ? machine : nil,
                brewer: spec.style == .filter ? brewer : nil
            )
            context.insert(entry)
        }

        try? context.save()
    }
}

enum SnapshotLaunch {
    static var isEnabled: Bool {
        #if DEBUG
        CommandLine.arguments.contains("--snapshot")
            || CommandLine.arguments.contains("-FASTLANE_SNAPSHOT")
        #else
        false
        #endif
    }
}
