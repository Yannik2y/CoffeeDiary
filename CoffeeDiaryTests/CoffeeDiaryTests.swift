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
            BrewEntry(coffeeName: "A", grinderSetting: 2, shotType: .double, doseGrams: 18, yieldGrams: 36, brewTimeSeconds: 25, rating: 4),
            BrewEntry(coffeeName: "B", grinderSetting: 2, shotType: .double, doseGrams: 18, yieldGrams: 36, brewTimeSeconds: 25, rating: 0)
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
        let old = BrewEntry(
            createdAt: Calendar.current.date(byAdding: .day, value: -40, to: now)!,
            coffeeName: "Old",
            grinderSetting: 2,
            shotType: .double,
            doseGrams: 18,
            yieldGrams: 36,
            brewTimeSeconds: 25
        )
        let recent = BrewEntry(
            createdAt: Calendar.current.date(byAdding: .day, value: -2, to: now)!,
            coffeeName: "Recent",
            grinderSetting: 2,
            shotType: .double,
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
            BrewEntry(coffeeName: "Ethiopia", grinderSetting: 2, shotType: .double, doseGrams: 18, yieldGrams: 36, brewTimeSeconds: 25, rating: 5),
            BrewEntry(coffeeName: "Ethiopia", grinderSetting: 2, shotType: .double, doseGrams: 18, yieldGrams: 36, brewTimeSeconds: 25, rating: 4),
            BrewEntry(coffeeName: "Kenya", grinderSetting: 2, shotType: .double, doseGrams: 18, yieldGrams: 36, brewTimeSeconds: 25, rating: 5)
        ]
        let groups = ChartAnalyticsService.topRatedGroups(brews, minCount: 2)
        #expect(groups.count == 1)
        #expect(groups.first?.name == "Ethiopia")
    }

    @Test func linearTrendOnPerfectLine() {
        let points = (1...5).map { (x: Double($0), y: Double($0 * 2)) }
        let trend = ChartAnalyticsService.linearTrend(points)
        #expect(trend != nil)
        #expect(abs((trend?.r2 ?? 0) - 1.0) < 0.001)
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
}
