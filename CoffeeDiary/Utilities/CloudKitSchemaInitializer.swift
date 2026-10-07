#if DEBUG
import CoreData
import Foundation
import SwiftData

/// One-shot helper to push the full SwiftData schema (including `CD_Brewer`) into
/// the CloudKit **Development** environment via `NSPersistentCloudKitContainer`.
///
/// Usage: launch a Debug build with `-InitializeCloudKitSchema`, then deploy
/// Development → Production in the CloudKit Console.
enum CloudKitSchemaInitializer {
    static let launchArgument = "-InitializeCloudKitSchema"

    static var isRequested: Bool {
        CommandLine.arguments.contains(launchArgument)
    }

    /// Creates a temporary CloudKit-backed store and calls `initializeCloudKitSchema`.
    /// Does not touch the app's durable store.
    @discardableResult
    static func runIfRequested(containerIdentifier: String) -> Bool {
        guard isRequested else { return false }

        print("CloudKitSchemaInitializer: starting schema init for \(containerIdentifier)")

        guard let model = NSManagedObjectModel.makeManagedObjectModel(
            for: CoffeeDiarySchemaV1.models
        ) else {
            print("CloudKitSchemaInitializer: FAILED — could not build NSManagedObjectModel")
            return true
        }

        let container = NSPersistentCloudKitContainer(
            name: "CoffeeDiarySchemaInit",
            managedObjectModel: model
        )

        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("CoffeeDiarySchemaInit-\(UUID().uuidString).sqlite")

        let description = NSPersistentStoreDescription(url: storeURL)
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: containerIdentifier
        )
        description.setOption(
            true as NSNumber,
            forKey: NSPersistentHistoryTrackingKey
        )
        description.setOption(
            true as NSNumber,
            forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey
        )
        container.persistentStoreDescriptions = [description]

        var loadError: Error?
        let loadGroup = DispatchGroup()
        loadGroup.enter()
        container.loadPersistentStores { _, error in
            loadError = error
            loadGroup.leave()
        }
        loadGroup.wait()

        if let loadError {
            print("CloudKitSchemaInitializer: FAILED — loadPersistentStores: \(loadError)")
            cleanupStore(at: storeURL)
            return true
        }

        do {
            try container.initializeCloudKitSchema(options: [])
            print("CloudKitSchemaInitializer: SUCCESS — Development schema updated (incl. CD_Brewer). Deploy Development → Production in CloudKit Console.")
        } catch {
            print("CloudKitSchemaInitializer: FAILED — initializeCloudKitSchema: \(error)")
        }

        cleanupStore(at: storeURL)
        return true
    }

    private static func cleanupStore(at url: URL) {
        let fm = FileManager.default
        for suffix in ["", "-shm", "-wal"] {
            let path = url.path + suffix
            try? fm.removeItem(atPath: path)
        }
    }
}
#endif
