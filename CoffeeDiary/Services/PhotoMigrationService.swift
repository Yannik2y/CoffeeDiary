import Foundation
import SwiftData

enum PhotoMigrationService {
    private static let cloudKitMigrationKey = "didMigratePhotosToCloudKit"

    @MainActor
    static func migrateIfNeeded(container: ModelContainer) {
        guard !UserDefaults.standard.bool(forKey: cloudKitMigrationKey) else { return }
        let context = container.mainContext

        migrateBeans(context)
        migrateGrinders(context)
        migrateMachines(context)
        migrateBrewers(context)

        try? context.save()
        UserDefaults.standard.set(true, forKey: cloudKitMigrationKey)
    }

    @MainActor
    static func migrateForTesting(container: ModelContainer) {
        let context = container.mainContext
        migrateBeans(context)
        migrateGrinders(context)
        migrateMachines(context)
        migrateBrewers(context)
        try? context.save()
    }

    private static func migrateBeans(_ context: ModelContext) {
        guard let beans = try? context.fetch(FetchDescriptor<Bean>()) else { return }
        for bean in beans {
            migratePhoto(photoData: { bean.photoData }, photoPath: { bean.photoPath }, setPhotoData: { bean.photoData = $0 }, setPhotoPath: { bean.photoPath = $0 })
        }
    }

    private static func migrateGrinders(_ context: ModelContext) {
        guard let items = try? context.fetch(FetchDescriptor<Grinder>()) else { return }
        for item in items {
            migratePhoto(photoData: { item.photoData }, photoPath: { item.photoPath }, setPhotoData: { item.photoData = $0 }, setPhotoPath: { item.photoPath = $0 })
        }
    }

    private static func migrateMachines(_ context: ModelContext) {
        guard let items = try? context.fetch(FetchDescriptor<Machine>()) else { return }
        for item in items {
            migratePhoto(photoData: { item.photoData }, photoPath: { item.photoPath }, setPhotoData: { item.photoData = $0 }, setPhotoPath: { item.photoPath = $0 })
        }
    }

    private static func migrateBrewers(_ context: ModelContext) {
        guard let items = try? context.fetch(FetchDescriptor<Brewer>()) else { return }
        for item in items {
            migratePhoto(photoData: { item.photoData }, photoPath: { item.photoPath }, setPhotoData: { item.photoData = $0 }, setPhotoPath: { item.photoPath = $0 })
        }
    }

    private static func migratePhoto(
        photoData: () -> Data?,
        photoPath: () -> String?,
        setPhotoData: (Data?) -> Void,
        setPhotoPath: (String?) -> Void
    ) {
        if let path = photoPath(), photoData() == nil, let diskData = PhotoStorage.loadPhoto(path: path) {
            setPhotoData(PhotoStorage.compressedJPEG(from: diskData))
            setPhotoPath(nil)
            return
        }

        if let existing = photoData(), let compressed = PhotoStorage.compressedJPEG(from: existing) {
            setPhotoData(compressed)
            setPhotoPath(nil)
        }
    }
}
