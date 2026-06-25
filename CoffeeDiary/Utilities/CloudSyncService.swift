import Foundation
import CloudKit
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
            return "iCloud could not be initialized. Data stays on this device only.".localized
        case .cloud:
            switch accountStatus {
            case .available:
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
    }

    func setStorageMode(_ mode: StorageMode) {
        storageMode = mode
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
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
            accountStatus = .couldNotDetermine
        }
        lastCheckedAt = Date()
    }
}
