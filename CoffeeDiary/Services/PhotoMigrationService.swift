import Foundation
import SwiftData

enum PhotoMigrationService {
    private static let cloudKitMigrationKey = "didMigratePhotosToCloudKit"

    @MainActor
    static func migrateIfNeeded(container: ModelContainer) async {
        guard !UserDefaults.standard.bool(forKey: cloudKitMigrationKey) else { return }
        let context = container.mainContext

        var pathsToDelete: [String] = []
        await migrateBeans(context, pathsToDelete: &pathsToDelete)
        await migrateGrinders(context, pathsToDelete: &pathsToDelete)
        await migrateMachines(context, pathsToDelete: &pathsToDelete)
        await migrateBrewers(context, pathsToDelete: &pathsToDelete)

        do {
            try context.save()
            let paths = pathsToDelete
            await Task.detached(priority: .utility) {
                for path in paths {
                    PhotoStorage.deletePhoto(path: path)
                }
                PhotoStorage.cleanupOrphanedPhotos()
            }.value
            UserDefaults.standard.set(true, forKey: cloudKitMigrationKey)
        } catch {
            print("Photo migration save failed: \(error.localizedDescription)")
            // Leave flag unset so migration retries on next launch.
        }
    }

    @MainActor
    static func migrateForTesting(container: ModelContainer) async {
        let context = container.mainContext
        var pathsToDelete: [String] = []
        await migrateBeans(context, pathsToDelete: &pathsToDelete)
        await migrateGrinders(context, pathsToDelete: &pathsToDelete)
        await migrateMachines(context, pathsToDelete: &pathsToDelete)
        await migrateBrewers(context, pathsToDelete: &pathsToDelete)
        try? context.save()
        for path in pathsToDelete {
            PhotoStorage.deletePhoto(path: path)
        }
    }

    @MainActor
    private static func migrateBeans(_ context: ModelContext, pathsToDelete: inout [String]) async {
        guard let beans = try? context.fetch(FetchDescriptor<Bean>()) else { return }
        for bean in beans {
            await migratePhoto(
                photoData: { bean.photoData },
                photoPath: { bean.photoPath },
                setPhotoData: { bean.photoData = $0 },
                setPhotoPath: { bean.photoPath = $0 },
                pathsToDelete: &pathsToDelete
            )
        }
    }

    @MainActor
    private static func migrateGrinders(_ context: ModelContext, pathsToDelete: inout [String]) async {
        guard let items = try? context.fetch(FetchDescriptor<Grinder>()) else { return }
        for item in items {
            await migratePhoto(
                photoData: { item.photoData },
                photoPath: { item.photoPath },
                setPhotoData: { item.photoData = $0 },
                setPhotoPath: { item.photoPath = $0 },
                pathsToDelete: &pathsToDelete
            )
        }
    }

    @MainActor
    private static func migrateMachines(_ context: ModelContext, pathsToDelete: inout [String]) async {
        guard let items = try? context.fetch(FetchDescriptor<Machine>()) else { return }
        for item in items {
            await migratePhoto(
                photoData: { item.photoData },
                photoPath: { item.photoPath },
                setPhotoData: { item.photoData = $0 },
                setPhotoPath: { item.photoPath = $0 },
                pathsToDelete: &pathsToDelete
            )
        }
    }

    @MainActor
    private static func migrateBrewers(_ context: ModelContext, pathsToDelete: inout [String]) async {
        guard let items = try? context.fetch(FetchDescriptor<Brewer>()) else { return }
        for item in items {
            await migratePhoto(
                photoData: { item.photoData },
                photoPath: { item.photoPath },
                setPhotoData: { item.photoData = $0 },
                setPhotoPath: { item.photoPath = $0 },
                pathsToDelete: &pathsToDelete
            )
        }
    }

    /// Migrates a single photo. Only clears `photoPath` when compressed data is available.
    @MainActor
    private static func migratePhoto(
        photoData: () -> Data?,
        photoPath: () -> String?,
        setPhotoData: (Data?) -> Void,
        setPhotoPath: (String?) -> Void,
        pathsToDelete: inout [String]
    ) async {
        if let path = photoPath(), photoData() == nil, let diskData = PhotoStorage.loadPhoto(path: path) {
            guard let compressed = await PhotoStorage.compressedJPEGAsync(from: diskData) else {
                // Keep photoPath so we can retry; do not orphan the disk file.
                return
            }
            setPhotoData(compressed)
            setPhotoPath(nil)
            pathsToDelete.append(path)
            return
        }

        if let existing = photoData(), let compressed = await PhotoStorage.compressedJPEGAsync(from: existing) {
            setPhotoData(compressed)
            if let path = photoPath() {
                setPhotoPath(nil)
                pathsToDelete.append(path)
            }
        }
    }
}
