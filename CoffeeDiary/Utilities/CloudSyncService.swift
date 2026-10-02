import Foundation
import CloudKit
import CoreData
import Observation

enum StorageMode: String {
    case cloud
    case local
    case memory
}

@Observable
@MainActor
final class CloudSyncService {
    static let iCloudContainerIdentifier = "iCloud.YC.CoffeeDiary"
    static let shared = CloudSyncService()

    private(set) var accountStatus: CKAccountStatus = .couldNotDetermine
    private(set) var storageMode: StorageMode = .cloud
    private(set) var lastCheckedAt: Date?
    private(set) var lastErrorMessage: String?
    /// Set when ModelContainer cloud init fails (local/memory fallback).
    private(set) var containerInitErrorMessage: String?
    private(set) var lastSyncEventAt: Date?
    private(set) var lastSyncEventSummary: String?
    private(set) var lastSyncEventFailed = false
    private(set) var pushRegistrationWarning: String?

    private var cloudKitEventObserver: NSObjectProtocol?

    var isCloudStorageActive: Bool { storageMode == .cloud }

    var isSyncAvailable: Bool {
        isCloudStorageActive && accountStatus == .available
    }

    var statusTitle: String {
        switch storageMode {
        case .memory:
            return "iCloud Sync Unavailable".localized
        case .local:
            return "Local Storage Only".localized
        case .cloud:
            switch accountStatus {
            case .available:
                if lastSyncEventFailed {
                    return "iCloud Sync Issue".localized
                }
                return "iCloud Sync Active".localized
            case .noAccount:
                return "Sign In to iCloud".localized
            case .restricted:
                return "iCloud Restricted".localized
            case .couldNotDetermine:
                return "Checking iCloud…".localized
            case .temporarilyUnavailable:
                return "iCloud Temporarily Unavailable".localized
            @unknown default:
                return "iCloud Status Unknown".localized
            }
        }
    }

    var statusDetail: String {
        switch storageMode {
        case .memory:
            return "Data is stored in memory only and will not persist or sync.".localized
        case .local:
            if let containerInitErrorMessage, !containerInitErrorMessage.isEmpty {
                return "iCloud could not be initialized (%@). Data stays on this device only. Quit and reopen the app to retry."
                    .localized(with: containerInitErrorMessage)
            }
            return "iCloud could not be initialized. Data stays on this device only. Quit and reopen the app to retry.".localized
        case .cloud:
            switch accountStatus {
            case .available:
                if lastSyncEventFailed, let lastSyncEventSummary {
                    return lastSyncEventSummary
                }
                if let lastSyncEventSummary {
                    return lastSyncEventSummary
                }
                return "Brews and equipment sync across your iPhone and iPad when signed into the same iCloud account.".localized
            case .noAccount:
                return "Sign in to iCloud in Settings to sync between your devices.".localized
            case .restricted:
                return "iCloud access is restricted on this device. Check Screen Time or device management settings.".localized
            case .couldNotDetermine:
                return "Verifying your iCloud account status…".localized
            case .temporarilyUnavailable:
                return "iCloud is temporarily unavailable. Sync will resume automatically.".localized
            @unknown default:
                return "Unable to determine iCloud status.".localized
            }
        }
    }

    var statusSymbolName: String {
        if lastSyncEventFailed { return "exclamationmark.icloud" }
        if isSyncAvailable { return "icloud.fill" }
        if storageMode == .local || storageMode == .memory { return "icloud.slash" }
        return "icloud"
    }

    private init() {
        NotificationCenter.default.addObserver(
            forName: .CKAccountChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshAccountStatus()
            }
        }

        cloudKitEventObserver = NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.handleCloudKitEvent(notification)
            }
        }
    }

    func setStorageMode(_ mode: StorageMode) {
        storageMode = mode
    }

    func recordContainerInitFailure(_ error: Error) {
        containerInitErrorMessage = error.localizedDescription
        lastErrorMessage = error.localizedDescription
    }

    func clearContainerInitFailure() {
        containerInitErrorMessage = nil
    }

    func recordPushRegistrationFailure(_ error: Error) {
        pushRegistrationWarning = "Live sync may be delayed until the next app open.".localized
        lastErrorMessage = error.localizedDescription
    }

    #if DEBUG
    func setAccountStatusForTesting(_ status: CKAccountStatus) {
        accountStatus = status
    }
    #endif

    func refreshAccountStatus() async {
        let container = CKContainer(identifier: Self.iCloudContainerIdentifier)
        do {
            accountStatus = try await container.accountStatus()
            if storageMode == .cloud {
                lastErrorMessage = nil
            }
        } catch {
            lastErrorMessage = error.localizedDescription
            accountStatus = .couldNotDetermine
        }
        lastCheckedAt = Date()
    }

    private func handleCloudKitEvent(_ notification: Notification) {
        guard let event = notification.userInfo?[
            NSPersistentCloudKitContainer.eventNotificationUserInfoKey
        ] as? NSPersistentCloudKitContainer.Event else {
            return
        }

        lastSyncEventAt = Date()

        let typeLabel: String
        switch event.type {
        case .setup:
            typeLabel = "Setup".localized
        case .import:
            typeLabel = "Import".localized
        case .export:
            typeLabel = "Export".localized
        @unknown default:
            typeLabel = "Sync".localized
        }

        if let error = event.error {
            lastSyncEventFailed = true
            lastErrorMessage = error.localizedDescription
            lastSyncEventSummary = "Last %@ failed: %@".localized(with: typeLabel, error.localizedDescription)
        } else if event.endDate != nil {
            lastSyncEventFailed = false
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .short
            let when = formatter.localizedString(for: event.endDate ?? Date(), relativeTo: Date())
            lastSyncEventSummary = "Last %@: %@".localized(with: typeLabel.lowercased(), when)
        }
    }
}
