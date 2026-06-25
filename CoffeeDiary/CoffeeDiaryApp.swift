import SwiftUI
import SwiftData
import Foundation

@main
struct CoffeeDiaryApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.scenePhase) private var scenePhase

    init() {
        if CommandLine.arguments.contains("--ui-testing") {
            if let bundleId = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleId)
            }
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                    OnboardingView()
                }
            }
            .tint(AppTheme.accent)
            .task {
                await CloudSyncService.shared.refreshAccountStatus()
                PhotoMigrationService.migrateIfNeeded(container: sharedModelContainer)
            }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                Task {
                    await CloudSyncService.shared.refreshAccountStatus()
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - SwiftData Container

enum ModelContainerFactory {
    static let iCloudContainerIdentifier = CloudSyncService.iCloudContainerIdentifier

    static func makeContainer() -> ModelContainer {
        let schema = Schema(versionedSchema: CoffeeDiarySchemaV1.self)

        do {
            let cloudConfig = ModelConfiguration(
                "Cloud",
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private(iCloudContainerIdentifier)
            )
            let container = try ModelContainer(for: schema, configurations: [cloudConfig])
            Task { @MainActor in
                CloudSyncService.shared.setStorageMode(.cloud)
            }
            return container
        } catch {
            print("SwiftData Cloud container init failed: \(error)")
            do {
                let localConfig = ModelConfiguration(
                    "Local",
                    schema: schema,
                    isStoredInMemoryOnly: false
                )
                let container = try ModelContainer(for: schema, configurations: [localConfig])
                Task { @MainActor in
                    CloudSyncService.shared.setStorageMode(.local)
                }
                return container
            } catch {
                print("SwiftData Local container init failed: \(error)")
                do {
                    let memoryConfig = ModelConfiguration(
                        "Memory",
                        schema: schema,
                        isStoredInMemoryOnly: true
                    )
                    let container = try ModelContainer(for: schema, configurations: [memoryConfig])
                    Task { @MainActor in
                        CloudSyncService.shared.setStorageMode(.memory)
                    }
                    return container
                } catch {
                    fatalError("Could not create ModelContainer (including in-memory): \(error)")
                }
            }
        }
    }
}

private let sharedModelContainer: ModelContainer = ModelContainerFactory.makeContainer()
