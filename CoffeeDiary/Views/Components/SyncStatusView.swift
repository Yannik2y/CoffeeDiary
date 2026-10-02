import SwiftUI

struct SyncStatusBanner: View {
    @Bindable private var syncService = CloudSyncService.shared
    var embeddedInList: Bool = false

    var body: some View {
        if !SnapshotLaunch.isEnabled, !syncService.isSyncAvailable || syncService.lastSyncEventFailed {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: syncService.statusSymbolName)
                    .font(.title3)
                    .foregroundStyle(AppTheme.accent)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(syncService.statusTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(syncService.statusDetail)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppTheme.cardBackground)
                    .shadow(color: AppTheme.cardShadow.opacity(0.2), radius: 6, x: 0, y: 2)
            )
            .padding(.horizontal, embeddedInList ? 0 : 20)
            .task {
                await syncService.refreshAccountStatus()
            }
        }
    }
}

struct SyncStatusSection: View {
    @Bindable private var syncService = CloudSyncService.shared
    @State private var showingRetryHelp = false

    var body: some View {
        Section("iCloud Sync".localized) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: syncService.statusSymbolName)
                    .font(.title2)
                    .foregroundStyle(
                        syncService.isSyncAvailable && !syncService.lastSyncEventFailed
                            ? .green
                            : AppTheme.accent
                    )
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 6) {
                    Text(syncService.statusTitle)
                        .font(.headline)
                    Text(syncService.statusDetail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)

            if syncService.isSyncAvailable, !syncService.lastSyncEventFailed {
                Label("Syncs between iPhone and iPad".localized, systemImage: "ipad.and.iphone")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let warning = syncService.pushRegistrationWarning {
                Label(warning, systemImage: "bell.slash")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let error = syncService.containerInitErrorMessage, syncService.storageMode == .local {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }

            Button("Refresh Status".localized) {
                Task {
                    await syncService.refreshAccountStatus()
                }
            }

            if syncService.storageMode == .local || syncService.storageMode == .memory {
                Button("Retry iCloud Sync".localized) {
                    showingRetryHelp = true
                }
            }
        }
        .task {
            await syncService.refreshAccountStatus()
        }
        .alert("Retry iCloud Sync".localized, isPresented: $showingRetryHelp) {
            Button("OK".localized, role: .cancel) {}
        } message: {
            Text("Quit Coffee Diary completely and open it again to reconnect to iCloud. Keep the same Apple ID on iPhone and iPad.".localized)
        }
    }
}
