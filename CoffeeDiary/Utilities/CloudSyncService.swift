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
    /// True after at least one CloudKit setup/import/export completed without error.
    private(set) var hasCompletedCloudKitEvent = false
    private(set) var pushRegistrationWarning: String?

    private var cloudKitEventObserver: NSObjectProtocol?

    var isCloudStorageActive: Bool { storageMode == .cloud }

    var isSyncAvailable: Bool {
        isCloudStorageActive && accountStatus == .available
    }

    /// Account + store look ready and CloudKit has completed at least one event successfully.
    var isSyncHealthy: Bool {
        isSyncAvailable && !lastSyncEventFailed && hasCompletedCloudKitEvent
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
                if !hasCompletedCloudKitEvent {
                    return "Connecting to iCloud…".localized
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
                if lastSyncEventFailed {
                    if let lastErrorMessage, lastErrorMessage.contains("partialFailure")
                        || lastErrorMessage.contains("[CKErrorDomain:2]") {
                        return "iCloud could not finish exporting data. If this persists on TestFlight, the Production CloudKit schema may need to be deployed from the CloudKit Dashboard.".localized
                    }
                    if let lastSyncEventSummary {
                        return lastSyncEventSummary
                    }
                }
                if let lastSyncEventSummary {
                    return lastSyncEventSummary
                }
                if !hasCompletedCloudKitEvent {
                    return "Waiting for the first sync with iCloud. Keep the app open briefly with an internet connection.".localized
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
        if isSyncHealthy { return "icloud.fill" }
        if storageMode == .local || storageMode == .memory { return "icloud.slash" }
        return "icloud"
    }

    /// Compact snapshot for support feedback and debugging.
    var diagnosticsSnapshot: String {
        let account: String
        switch accountStatus {
        case .available: account = "available"
        case .noAccount: account = "noAccount"
        case .restricted: account = "restricted"
        case .couldNotDetermine: account = "couldNotDetermine"
        case .temporarilyUnavailable: account = "temporarilyUnavailable"
        @unknown default: account = "unknown"
        }

        var lines = [
            "mode=\(storageMode.rawValue)",
            "account=\(account)",
            "healthy=\(isSyncHealthy)",
            "completedEvent=\(hasCompletedCloudKitEvent)",
            "eventFailed=\(lastSyncEventFailed)",
            "container=\(Self.iCloudContainerIdentifier)"
        ]
        if let lastSyncEventSummary {
            lines.append("lastEvent=\(lastSyncEventSummary)")
        }
        if let containerInitErrorMessage {
            lines.append("containerInit=\(containerInitErrorMessage)")
        }
        if let pushRegistrationWarning {
            lines.append("push=\(pushRegistrationWarning)")
        }
        if let lastErrorMessage {
            lines.append("lastError=\(lastErrorMessage)")
        }
        return lines.joined(separator: "; ")
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

    /// Must run on the main actor before `ModelContainer` CloudKit init so setup events are not missed.
    static func prepareForContainerLaunch() {
        MainActor.assumeIsolated {
            _ = CloudSyncService.shared
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

    func setHasCompletedCloudKitEventForTesting(_ value: Bool) {
        hasCompletedCloudKitEvent = value
    }
    #endif

    func refreshAccountStatus() async {
        let container = CKContainer(identifier: Self.iCloudContainerIdentifier)
        do {
            accountStatus = try await container.accountStatus()
            // Keep CloudKit event / push errors visible after a successful account check.
            if storageMode == .cloud, !lastSyncEventFailed, pushRegistrationWarning == nil {
                lastErrorMessage = nil
            }
            // Probes Production/Development container access (surfaces schema / permission errors).
            if accountStatus == .available {
                do {
                    _ = try await container.userRecordID()
                } catch {
                    lastErrorMessage = error.localizedDescription
                    if !lastSyncEventFailed {
                        lastSyncEventSummary = "iCloud container check failed: %@".localized(with: error.localizedDescription)
                    }
                }
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
            let detail = Self.detailedCloudKitErrorDescription(error)
            lastErrorMessage = detail
            lastSyncEventSummary = "Last %@ failed: %@".localized(with: typeLabel, detail)
        } else if event.endDate != nil {
            lastSyncEventFailed = false
            hasCompletedCloudKitEvent = true
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .short
            let when = formatter.localizedString(for: event.endDate ?? Date(), relativeTo: Date())
            lastSyncEventSummary = "Last %@: %@".localized(with: typeLabel.lowercased(), when)
        }
    }

    /// Flattens `CKError.partialFailure` and Cocoa wrappers so Formspree/diagnostics show the real cause
    /// (e.g. “Cannot create or modify field … in production schema”).
    static func detailedCloudKitErrorDescription(_ error: Error) -> String {
        var parts: [String] = []
        appendCloudKitErrorDetails(error, into: &parts, depth: 0)
        return parts.isEmpty ? error.localizedDescription : parts.joined(separator: " | ")
    }

    private static func appendCloudKitErrorDetails(_ error: Error, into parts: inout [String], depth: Int) {
        guard depth < 4 else { return }
        let ns = error as NSError
        let headline = ns.localizedDescription
        if parts.isEmpty || parts.last != headline {
            parts.append(headline)
        }
        parts.append("[\(ns.domain):\(ns.code)]")

        if let server = ns.userInfo["ServerErrorDescription"] as? String
            ?? ns.userInfo["CKServerDescriptionErrorKey"] as? String
            ?? ns.userInfo[NSLocalizedFailureReasonErrorKey] as? String {
            parts.append("server=\(server)")
        }

        if let ckError = error as? CKError {
            if ckError.code == .partialFailure {
                parts.append("partialFailure")
            }
            if let partial = ckError.partialErrorsByItemID {
                for (_, nested) in partial {
                    appendCloudKitErrorDetails(nested, into: &parts, depth: depth + 1)
                }
            }
        } else if ns.domain == CKError.errorDomain, ns.code == CKError.Code.partialFailure.rawValue {
            parts.append("partialFailure")
            if let partial = ns.userInfo[CKPartialErrorsByItemIDKey] as? [AnyHashable: Error] {
                for (_, nested) in partial {
                    appendCloudKitErrorDetails(nested, into: &parts, depth: depth + 1)
                }
            }
        }

        if let underlying = ns.userInfo[NSUnderlyingErrorKey] as? Error {
            appendCloudKitErrorDetails(underlying, into: &parts, depth: depth + 1)
        }
    }
}
