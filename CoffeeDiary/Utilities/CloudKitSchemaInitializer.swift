#if DEBUG
import CloudKit
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
    static let resultFileName = "cloudkit-schema-init.txt"

    static var isRequested: Bool {
        CommandLine.arguments.contains(launchArgument)
    }

    /// Creates a temporary CloudKit-backed store and calls `initializeCloudKitSchema`.
    /// Does not touch the app's durable store.
    @discardableResult
    static func runIfRequested(containerIdentifier: String) -> Bool {
        guard isRequested else { return false }

        // Fresh result file for this run.
        clearResultFiles()
        log("CloudKitSchemaInitializer: starting schema init for \(containerIdentifier)")

        let accountStatus = waitForAccountStatus(containerIdentifier: containerIdentifier)
        log("CloudKitSchemaInitializer: CKAccountStatus=\(accountStatusLabel(accountStatus))")
        guard accountStatus == .available else {
            log("CloudKitSchemaInitializer: FAILED — Simulator is not signed into iCloud with a usable account. Sign in under Settings → Apple Account, then relaunch with -InitializeCloudKitSchema.")
            return true
        }

        guard let model = NSManagedObjectModel.makeManagedObjectModel(
            for: CoffeeDiarySchemaV1.models
        ) else {
            log("CloudKitSchemaInitializer: FAILED — could not build NSManagedObjectModel")
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
            log("CloudKitSchemaInitializer: FAILED — loadPersistentStores: \(loadError)")
            cleanupStore(at: storeURL)
            return true
        }

        do {
            try container.initializeCloudKitSchema(options: [])
            log("CloudKitSchemaInitializer: SUCCESS — Development schema updated (incl. CD_Brewer). Deploy Development → Production in CloudKit Console.")
        } catch {
            log("CloudKitSchemaInitializer: FAILED — initializeCloudKitSchema: \(error)")
        }

        cleanupStore(at: storeURL)
        return true
    }

    private static func waitForAccountStatus(containerIdentifier: String) -> CKAccountStatus {
        let group = DispatchGroup()
        var status: CKAccountStatus = .couldNotDetermine
        group.enter()
        CKContainer(identifier: containerIdentifier).accountStatus { accountStatus, _ in
            status = accountStatus
            group.leave()
        }
        _ = group.wait(timeout: .now() + 30)
        return status
    }

    private static func accountStatusLabel(_ status: CKAccountStatus) -> String {
        switch status {
        case .available: return "available"
        case .noAccount: return "noAccount"
        case .restricted: return "restricted"
        case .couldNotDetermine: return "couldNotDetermine"
        case .temporarilyUnavailable: return "temporarilyUnavailable"
        @unknown default: return "unknown(\(status.rawValue))"
        }
    }

    /// Writes to stdout, ASL, Documents, and /tmp so the host can read the result
    /// even when `simctl launch --console` never returns.
    private static func log(_ message: String) {
        print(message)
        NSLog("%@", message)
        let line = Data((message + "\n").utf8)
        for url in resultURLs() {
            if FileManager.default.fileExists(atPath: url.path),
               let handle = try? FileHandle(forWritingTo: url) {
                handle.seekToEndOfFile()
                handle.write(line)
                try? handle.close()
            } else {
                try? FileManager.default.createDirectory(
                    at: url.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try? line.write(to: url)
            }
        }
    }

    private static func clearResultFiles() {
        for url in resultURLs() {
            try? FileManager.default.removeItem(at: url)
        }
    }

    private static func resultURLs() -> [URL] {
        var urls = [
            URL(fileURLWithPath: "/tmp/\(resultFileName)"),
            FileManager.default.temporaryDirectory.appendingPathComponent(resultFileName)
        ]
        if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            urls.append(docs.appendingPathComponent(resultFileName))
        }
        return urls
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
