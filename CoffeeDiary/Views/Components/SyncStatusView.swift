import SwiftUI

struct SyncStatusBanner: View {
    @Bindable private var syncService = CloudSyncService.shared

    var body: some View {
        if !syncService.isSyncAvailable {
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
            .padding(.horizontal, 20)
            .task {
                await syncService.refreshAccountStatus()
            }
        }
    }
}

struct SyncStatusSection: View {
    @Bindable private var syncService = CloudSyncService.shared

    var body: some View {
        Section("iCloud Sync".localized) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: syncService.statusSymbolName)
                    .font(.title2)
                    .foregroundStyle(syncService.isSyncAvailable ? .green : AppTheme.accent)
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

            if syncService.isSyncAvailable {
                Label("Syncs between iPhone and iPad".localized, systemImage: "ipad.and.iphone")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Button("Refresh Status".localized) {
                Task {
                    await syncService.refreshAccountStatus()
                }
            }
        }
        .task {
            await syncService.refreshAccountStatus()
        }
    }
}
