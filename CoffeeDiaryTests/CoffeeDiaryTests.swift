//
//  CoffeeDiaryTests.swift
//  CoffeeDiaryTests
//
//  Created by Yannik Chlechowitz on 16.11.25.
//

import Foundation
import Testing
import SwiftData
import UIKit
import CloudKit
@testable import CoffeeDiary

struct FormattersTests {
    @Test func ratioHandlesZeroDose() {
        #expect(Formatters.ratioString(dose: 0, yield: 30) == "—")
    }
    
    @Test func ratioFormatsOneDecimal() {
        let ratio = Formatters.ratioString(dose: 18, yield: 36)
        #expect(ratio == "1:2")
    }
    
    @Test func secondsFormatterProducesMinutesAndSeconds() {
        #expect(Formatters.secondsString(125) == "2:05")
        #expect(Formatters.secondsString(0) == "0:00")
    }
}

struct BrewEntryModelTests {
    @Test func brewRatioReflectsDoseAndYield() {
        let entry = BrewEntry(
            coffeeName: "Test",
            grinderSetting: 2.1,
            shotType: .double,
            doseGrams: 20,
            yieldGrams: 40,
            brewTimeSeconds: 30
        )
        #expect(entry.brewRatio == 2.0)
    }
    
    @Test func brewRatioReturnsZeroWhenDoseMissing() {
        let entry = BrewEntry(
            coffeeName: "Test",
            grinderSetting: 2.1,
            shotType: .double,
            doseGrams: 0,
            yieldGrams: 40,
            brewTimeSeconds: 30
        )
        #expect(entry.brewRatio == 0)
    }
    @Test func preInfusionMetricsPersist() {
        let entry = BrewEntry(
            coffeeName: "Pressure Test",
            grinderSetting: 3.2,
            shotType: .single,
            doseGrams: 19,
            yieldGrams: 28,
            brewTimeSeconds: 32,
            preInfusionTimeSeconds: 8,
            brewPressureBar: 7.5
        )
        #expect(entry.preInfusionTimeSeconds == 8)
        #expect(entry.brewPressureBar == 7.5)
    }
    
    @Test func preInfusionMetricsDefaultToZero() {
        let entry = BrewEntry(
            coffeeName: "Defaults",
            grinderSetting: 1.8,
            shotType: .double,
            doseGrams: 18,
            yieldGrams: 36,
            brewTimeSeconds: 28
        )
        #expect(entry.preInfusionTimeSeconds == 0)
        #expect(entry.brewPressureBar == 0)
    }

}

struct CloudSyncServiceTests {
    @Test @MainActor func cloudStorageWithAvailableAccountIsSyncReady() {
        let service = CloudSyncService.shared
        service.setStorageMode(.cloud)
        service.setAccountStatusForTesting(.available)
        #expect(service.isSyncAvailable == true)
        #expect(service.statusTitle == "iCloud Sync Active".localized)
    }

    @Test @MainActor func localStorageIsNeverSyncReady() {
        let service = CloudSyncService.shared
        service.setStorageMode(.local)
        service.setAccountStatusForTesting(.available)
        #expect(service.isSyncAvailable == false)
        #expect(service.statusTitle == "Local Storage Only".localized)
    }

    @Test @MainActor func cloudStorageWithoutAccountShowsSignIn() {
        let service = CloudSyncService.shared
        service.setStorageMode(.cloud)
        service.setAccountStatusForTesting(.noAccount)
        #expect(service.isSyncAvailable == false)
        #expect(service.statusTitle == "Sign In to iCloud".localized)
    }
}

struct BrewEntryDuplicateTests {
    @Test func duplicateCopiesCoreFields() {
        let original = BrewEntry(
            coffeeName: "Ethiopia",
            grinderSetting: 2.5,
            shotType: .double,
            doseGrams: 18,
            yieldGrams: 36,
            brewTimeSeconds: 28,
            rating: 4,
            notes: "Great shot"
        )
        let copy = BrewEntry.duplicate(from: original)
        #expect(copy.coffeeName == original.coffeeName)
        #expect(copy.doseGrams == original.doseGrams)
        #expect(copy.yieldGrams == original.yieldGrams)
        #expect(copy.rating == original.rating)
        #expect(copy.id != original.id)
    }
}

struct BrewListFilterTests {
    @Test func filtersByMinimumRating() {
        let brews = [
            BrewEntry(coffeeName: "A", grinderSetting: 2, shotType: .double, doseGrams: 18, yieldGrams: 36, brewTimeSeconds: 25, rating: 5),
            BrewEntry(coffeeName: "B", grinderSetting: 2, shotType: .double, doseGrams: 18, yieldGrams: 36, brewTimeSeconds: 25, rating: 2)
        ]
        let criteria = BrewFilterCriteria(minRating: 4)
        let filtered = BrewListFilter.apply(criteria, to: brews)
        #expect(filtered.count == 1)
        #expect(filtered.first?.coffeeName == "A")
    }

    @Test func searchMatchesBeanName() {
        let bean = Bean(name: "Yirgacheffe")
        let brew = BrewEntry(coffeeName: "Morning", grinderSetting: 2, shotType: .double, doseGrams: 18, yieldGrams: 36, brewTimeSeconds: 25, bean: bean)
        let criteria = BrewFilterCriteria(searchText: "yirga")
        let filtered = BrewListFilter.apply(criteria, to: [brew])
        #expect(filtered.count == 1)
    }

    @Test @MainActor func filtersByMachineAndGrinder() {
        let machineA = Machine(name: "A")
        let machineB = Machine(name: "B")
        let grinder = Grinder(name: "G")
        let onA = BrewEntry(coffeeName: "onA", grinderSetting: 2, shotType: .double, doseGrams: 18, yieldGrams: 36, brewTimeSeconds: 25, grinder: grinder, machine: machineA)
        let onB = BrewEntry(coffeeName: "onB", grinderSetting: 2, shotType: .double, doseGrams: 18, yieldGrams: 36, brewTimeSeconds: 25, machine: machineB)
        let none = BrewEntry(coffeeName: "none", grinderSetting: 2, shotType: .double, doseGrams: 18, yieldGrams: 36, brewTimeSeconds: 25)

        let byMachine = BrewListFilter.apply(BrewFilterCriteria(machineId: machineA.id), to: [onA, onB, none])
        #expect(byMachine.map(\.coffeeName) == ["onA"])

        let byGrinder = BrewListFilter.apply(BrewFilterCriteria(grinderId: grinder.id), to: [onA, onB, none])
        #expect(byGrinder.map(\.coffeeName) == ["onA"])

        let mismatch = BrewListFilter.apply(BrewFilterCriteria(machineId: machineB.id, grinderId: grinder.id), to: [onA, onB, none])
        #expect(mismatch.isEmpty)

        #expect(BrewFilterCriteria(machineId: machineA.id).hasActiveFilters)
        #expect(BrewFilterCriteria(machineId: machineA.id).hashValue != BrewFilterCriteria().hashValue)
    }
}

struct FlowConfigurationTests {
    @Test func weatherStepEnabledForEspressoByDefault() {
        let config = FlowConfiguration()
        #expect(config.espressoWeather == true)
        #expect(config.isEnabled(.weather, for: .espresso) == true)
    }
}

struct BeanModelTests {
    @Test func daysSinceRoastCalculatesFromRoastDate() {
        let bean = Bean(name: "Test", roastDate: Calendar.current.date(byAdding: .day, value: -10, to: Date()))
        #expect(bean.daysSinceRoast == 10)
    }

    @Test func isPastPeakAfter28Days() {
        let bean = Bean(name: "Old", roastDate: Calendar.current.date(byAdding: .day, value: -30, to: Date()))
        #expect(bean.isPastPeak == true)
    }
}

struct DialInAssistantTests {
    @Test func returnsNilWithFewBrews() {
        let bean = Bean(name: "Test")
        let brews = [
            BrewEntry(coffeeName: "A", grinderSetting: 2, shotType: .double, doseGrams: 18, yieldGrams: 36, brewTimeSeconds: 25, bean: bean)
        ]
        #expect(DialInAssistant.suggestion(for: bean, in: brews) == nil)
    }
}

struct ChartAnalyticsTests {
    @Test func averageRatingExcludesUnratedBrews() {
        let brews = [
            ChartBrewRecord(coffeeName: "A", doseGrams: 18, yieldGrams: 36, brewTimeSeconds: 25, rating: 4),
            ChartBrewRecord(coffeeName: "B", doseGrams: 18, yieldGrams: 36, brewTimeSeconds: 25, rating: 0)
        ]
        #expect(ChartAnalyticsService.averageRating(brews) == 4)
    }

    @Test func rollingAverageUsesTrailingWindow() {
        let now = Date()
        let points = (0..<5).map { index in
            (date: Calendar.current.date(byAdding: .day, value: index, to: now)!, value: Double(index + 1))
        }
        let rolling = ChartAnalyticsService.rollingAverage(points, window: 3)
        #expect(rolling.count == 3)
        #expect(rolling[0].y == 2)
        #expect(rolling[2].y == 4)
    }

    @Test func filterByTimeRangeExcludesOlderBrews() {
        let now = Date()
        let old = ChartBrewRecord(
            createdAt: Calendar.current.date(byAdding: .day, value: -40, to: now)!,
            coffeeName: "Old",
            doseGrams: 18,
            yieldGrams: 36,
            brewTimeSeconds: 25
        )
        let recent = ChartBrewRecord(
            createdAt: Calendar.current.date(byAdding: .day, value: -2, to: now)!,
            coffeeName: "Recent",
            doseGrams: 18,
            yieldGrams: 36,
            brewTimeSeconds: 25
        )
        let options = ChartFilterOptions(timeRange: .last30Days)
        let filtered = ChartAnalyticsService.filter([old, recent], options: options, now: now)
        #expect(filtered.count == 1)
        #expect(filtered.first?.coffeeName == "Recent")
    }

    @Test func topRatedGroupsRespectMinimumCount() {
        let brews = [
            ChartBrewRecord(coffeeName: "Ethiopia", doseGrams: 18, yieldGrams: 36, brewTimeSeconds: 25, rating: 5),
            ChartBrewRecord(coffeeName: "Ethiopia", doseGrams: 18, yieldGrams: 36, brewTimeSeconds: 25, rating: 4),
            ChartBrewRecord(coffeeName: "Kenya", doseGrams: 18, yieldGrams: 36, brewTimeSeconds: 25, rating: 5)
        ]
        let groups = ChartAnalyticsService.topRatedGroups(brews, minCount: 2)
        #expect(groups.count == 1)
        #expect(groups.first?.name == "Ethiopia")
    }

    @Test func linearTrendOnPerfectLine() {
        let points = (1...5).map { (x: Double($0), y: Double($0 * 2)) }
        let trend = ChartAnalyticsService.linearTrend(points)
        #expect(trend != nil)
        #expect(abs((trend?.r2 ?? 0) - 1) < 0.001)
    }

    @Test func allStyleUsesEspressoForRatioSeries() {
        let brews = [
            ChartBrewRecord(
                coffeeName: "Espresso",
                brewStyle: .espresso,
                doseGrams: 18,
                yieldGrams: 36,
                brewTimeSeconds: 28,
                rating: 5
            ),
            ChartBrewRecord(
                coffeeName: "Filter",
                brewStyle: .filter,
                doseGrams: 15,
                yieldGrams: 250,
                brewTimeSeconds: 200,
                rating: 4
            )
        ]
        let dashboard = ChartAnalyticsService.buildDashboard(
            from: brews,
            options: ChartFilterOptions(timeRange: .all, brewStyle: nil)
        )
        #expect(dashboard.ratioOverTime.points.count == 1)
        #expect(abs(dashboard.ratioOverTime.points[0].y - 2.0) < 0.01)
        #expect(dashboard.kpis.first(where: { $0.id == "ratio" })?.value.contains("2") == true)
        #expect(dashboard.kpis.first(where: { $0.id == "time" })?.value == "28s")
        #expect(dashboard.kpis.first(where: { $0.id == "count" })?.value == "2")
    }

    @Test func filterStyleKeepsFilterRatioScale() {
        let brews = [
            ChartBrewRecord(
                coffeeName: "Filter A",
                brewStyle: .filter,
                doseGrams: 15,
                yieldGrams: 250,
                brewTimeSeconds: 200,
                rating: 4
            ),
            ChartBrewRecord(
                coffeeName: "Filter B",
                brewStyle: .filter,
                doseGrams: 15,
                yieldGrams: 240,
                brewTimeSeconds: 190,
                rating: 5
            )
        ]
        let dashboard = ChartAnalyticsService.buildDashboard(
            from: brews,
            options: ChartFilterOptions(timeRange: .all, brewStyle: .filter)
        )
        #expect(dashboard.ratioOverTime.points.count == 2)
        #expect(dashboard.ratioOverTime.referenceY == nil)
        #expect(dashboard.kpis.first(where: { $0.id == "time" })?.value == "195s")
    }
}

struct PhotoStorageTests {
    @Test func compressedJPEGReducesLargeImage() throws {
        let size = CGSize(width: 3000, height: 2000)
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        UIColor.red.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        let sourceData = try #require(image?.jpegData(compressionQuality: 1))
        let compressed = try #require(PhotoStorage.compressedJPEG(from: sourceData))
        #expect(compressed.count < sourceData.count)
    }
}

struct PhotoMigrationServiceTests {
    @Test @MainActor func migratesDiskPhotoIntoCloudKitReadyData() throws {
        let schema = Schema(versionedSchema: CoffeeDiarySchemaV1.self)
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let sourceImage = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100)).image { ctx in
            UIColor.blue.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        }
        let sourceData = try #require(sourceImage.jpegData(compressionQuality: 0.9))
        let filename = try #require(PhotoStorage.savePhoto(sourceData))

        let bean = Bean(name: "Migration Test", photoPath: filename)
        context.insert(bean)
        try context.save()

        PhotoMigrationService.migrateForTesting(container: container)

        #expect(bean.photoData != nil)
        #expect(bean.photoPath == nil)
    }

    @Test @MainActor func compressesExistingInlinePhotoData() throws {
        let schema = Schema(versionedSchema: CoffeeDiarySchemaV1.self)
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let sourceImage = UIGraphicsImageRenderer(size: CGSize(width: 800, height: 600)).image { ctx in
            UIColor.green.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 800, height: 600))
        }
        let sourceData = try #require(sourceImage.jpegData(compressionQuality: 1))
        let bean = Bean(name: "Inline Test", photoData: sourceData)
        context.insert(bean)
        try context.save()

        PhotoMigrationService.migrateForTesting(container: container)

        #expect(bean.photoData != nil)
        #expect(bean.photoPath == nil)
        #expect(bean.photoData!.count <= sourceData.count)
    }

    @Test @MainActor func keepsPhotoPathWhenDataIsNotAnImage() throws {
        let schema = Schema(versionedSchema: CoffeeDiarySchemaV1.self)
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let filename = "\(UUID().uuidString).jpg"
        let url = PhotoStorage.photosDirectory.appendingPathComponent(filename)
        try Data("not-an-image".utf8).write(to: url)

        let bean = Bean(name: "Corrupt Photo", photoPath: filename)
        context.insert(bean)
        try context.save()

        PhotoMigrationService.migrateForTesting(container: container)

        #expect(bean.photoData == nil)
        #expect(bean.photoPath == filename)

        try? FileManager.default.removeItem(at: url)
    }
}

struct BrewExportServiceTests {
    @Test func csvEscapeQuotesNewlinesAndCommas() {
        #expect(BrewExportService.csvEscape("plain") == "plain")
        #expect(BrewExportService.csvEscape("a,b") == "\"a,b\"")
        #expect(BrewExportService.csvEscape("line1\nline2") == "\"line1\nline2\"")
        #expect(BrewExportService.csvEscape("say \"hi\"") == "\"say \"\"hi\"\"\"")
    }

    @Test func exportCSVIncludesEscapedNotes() {
        let brew = BrewEntry(
            coffeeName: "Test",
            grinderSetting: 2,
            shotType: .double,
            doseGrams: 18,
            yieldGrams: 36,
            brewTimeSeconds: 25,
            notes: "First line\nSecond, quoted \"note\""
        )
        let csv = BrewExportService.exportCSV(brews: [brew])
        #expect(csv.contains("\"First line\nSecond, quoted \"\"note\"\"\""))
    }
}

struct BrewListSearchCaseTests {
    @Test func searchIsCaseInsensitiveForQuery() {
        let brew = BrewEntry(
            coffeeName: "Yirgacheffe",
            grinderSetting: 2,
            shotType: .double,
            doseGrams: 18,
            yieldGrams: 36,
            brewTimeSeconds: 25
        )
        let criteria = BrewFilterCriteria(searchText: "YIRGA")
        let filtered = BrewListFilter.apply(criteria, to: [brew])
        #expect(filtered.count == 1)
    }
}

struct DialInAssistantOrderingTests {
    @Test func usesMostRecentBrewAsLatestRegardlessOfInputOrder() {
        let bean = Bean(name: "DialInBean")
        let older = BrewEntry(
            createdAt: Date().addingTimeInterval(-3600),
            coffeeName: "Old",
            grinderSetting: 2,
            shotType: .double,
            doseGrams: 18,
            yieldGrams: 36,
            brewTimeSeconds: 28,
            rating: 2,
            bean: bean
        )
        let mid = BrewEntry(
            createdAt: Date().addingTimeInterval(-1800),
            coffeeName: "Mid",
            grinderSetting: 2,
            shotType: .double,
            doseGrams: 18,
            yieldGrams: 36,
            brewTimeSeconds: 28,
            rating: 2,
            bean: bean
        )
        let newest = BrewEntry(
            createdAt: Date(),
            coffeeName: "New",
            grinderSetting: 2,
            shotType: .double,
            doseGrams: 18,
            yieldGrams: 36,
            brewTimeSeconds: 28,
            rating: 5,
            bean: bean
        )
        // Pass unsorted (oldest first) to ensure assistant sorts internally.
        let suggestion = DialInAssistant.suggestion(for: bean, in: [older, mid, newest])
        #expect(suggestion != nil)
        #expect(suggestion?.suggestedDose == newest.doseGrams)
    }
}

struct ActiveStationTests {
    @Test @MainActor func setActiveMachineClearsOtherActives() {
        let m1 = Machine(name: "A", isActive: true)
        let m2 = Machine(name: "B", isActive: false)
        BrewStore.shared.applyActiveMachineSelection(m2, isActive: true, allMachines: [m1, m2])
        #expect(m1.isActive == false)
        #expect(m2.isActive == true)
    }

    @Test @MainActor func reconcileKeepsSingleActiveMachine() {
        let m1 = Machine(name: "A", isActive: true)
        let m2 = Machine(name: "B", isActive: true)
        BrewStore.shared.reconcileActiveEquipment(machines: [m1, m2], grinders: [])
        let activeCount = [m1, m2].filter(\.isActive).count
        #expect(activeCount == 1)
    }
}

struct EquipmentCatalogTests {
    @Test func catalogLoadsModelsForBothCategories() {
        #expect(!EquipmentCatalog.models(for: .machine).isEmpty)
        #expect(!EquipmentCatalog.models(for: .grinder).isEmpty)
    }

    @Test func everyModelReferencesKnownBrandAndMatchingSilhouette() {
        for model in EquipmentCatalog.models {
            #expect(BrandDatabase.brand(id: model.brandId) != nil, "Unknown brand \(model.brandId) for \(model.id)")
            #expect(model.silhouette.category == model.category, "Silhouette mismatch for \(model.id)")
        }
    }

    @Test func modelIdsAreUnique() {
        let ids = EquipmentCatalog.models.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func filtersByBrandAndCategory() {
        let profitecMachines = EquipmentCatalog.models(for: .machine, brandId: "profitec")
        #expect(!profitecMachines.isEmpty)
        #expect(profitecMachines.allSatisfy { $0.brandId == "profitec" && $0.category == .machine })
        #expect(EquipmentCatalog.models(for: .grinder, brandId: "profitec").isEmpty)
    }

    @Test func searchMatchesModelAndBrandName() {
        let byModel = EquipmentCatalog.search("pro 700", category: .machine)
        #expect(byModel.contains { $0.id == "profitec_pro_700" })
        let byBrand = EquipmentCatalog.search("eureka", category: .grinder)
        #expect(!byBrand.isEmpty)
        #expect(byBrand.allSatisfy { $0.brandId == "eureka" })
    }

    @Test func burrDescriptionCombinesTypeAndSize() {
        let model = EquipmentCatalog.model(id: "df64_gen_2")
        #expect(model?.burrDescription == "\("Flat burrs".localized) 64 mm")
        let handGrinder = EquipmentCatalog.model(id: "comandante_c40_mk4")
        #expect(handGrinder?.burrDescription == "Conical burrs".localized)
    }
}

struct EquipmentSilhouetteTests {
    @Test func explicitChoiceWinsOverCatalogModel() {
        let resolved = EquipmentSilhouette.resolve(
            silhouetteId: EquipmentSilhouette.machineLever.rawValue,
            modelId: "profitec_pro_700",
            category: .machine
        )
        #expect(resolved == .machineLever)
    }

    @Test func catalogModelUsedWithoutExplicitChoice() {
        let resolved = EquipmentSilhouette.resolve(silhouetteId: nil, modelId: "niche_zero", category: .grinder)
        #expect(resolved == .grinderSingleDose)
    }

    @Test func ignoresSilhouetteFromOtherCategory() {
        let resolved = EquipmentSilhouette.resolve(
            silhouetteId: EquipmentSilhouette.grinderHand.rawValue,
            modelId: nil,
            category: .machine
        )
        #expect(resolved == EquipmentSilhouette.defaultSilhouette(for: .machine))
    }

    @Test func machineAndGrinderExposeResolvedSilhouette() {
        let machine = Machine(name: "Bianca", modelId: "lelit_bianca")
        #expect(machine.silhouette == .machineE61)
        let grinder = Grinder(name: "Old", silhouetteId: "not_a_silhouette")
        #expect(grinder.silhouette == .grinderHopper)
    }
}

struct GeneratedCoffeeNameTests {
    @Test func usesTrimmedBeanName() {
        let bean = Bean(name: "  Ethiopia Yirgacheffe  ")
        let name = BrewEntry.generatedCoffeeName(bean: bean, style: .espresso)
        #expect(name == "Ethiopia Yirgacheffe")
    }

    @Test func fallsBackToEspressoStyleWithoutBean() {
        let name = BrewEntry.generatedCoffeeName(bean: nil, style: .espresso)
        #expect(name == "Espresso".localized)
    }

    @Test func fallsBackToFilterStyleWithoutBean() {
        let name = BrewEntry.generatedCoffeeName(bean: nil, style: .filter)
        #expect(name == "Filter".localized)
    }

    @Test func treatsBlankBeanNameAsMissing() {
        let bean = Bean(name: "   ")
        let name = BrewEntry.generatedCoffeeName(bean: bean, style: .filter)
        #expect(name == "Filter".localized)
    }
}

