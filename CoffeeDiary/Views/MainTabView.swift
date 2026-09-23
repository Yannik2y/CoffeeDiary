import SwiftUI
import SwiftData

struct MainTabView: View {
    var body: some View {
        TabView {
            BrewListView()
                .tabItem {
                    Label("Diary".localized, systemImage: "cup.and.saucer.fill")
                }
                .accessibilityIdentifier("tabDiary")

            ChartsView()
                .tabItem {
                    Label("Stats".localized, systemImage: "chart.xyaxis.line")
                }
                .accessibilityIdentifier("tabStats")

            EquipmentManagementView(embedded: true)
                .tabItem {
                    Label("Gear".localized, systemImage: "wrench.and.screwdriver")
                }
                .accessibilityIdentifier("tabGear")

            SettingsView()
                .tabItem {
                    Label("Settings".localized, systemImage: "gearshape")
                }
                .accessibilityIdentifier("tabSettings")
        }
    }
}
