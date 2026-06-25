import SwiftUI
import SwiftData

struct MainTabView: View {
    var body: some View {
        TabView {
            BrewListView()
                .tabItem {
                    Label("Diary".localized, systemImage: "cup.and.saucer.fill")
                }

            ChartsView()
                .tabItem {
                    Label("Stats".localized, systemImage: "chart.xyaxis.line")
                }

            EquipmentManagementView(embedded: true)
                .tabItem {
                    Label("Gear".localized, systemImage: "wrench.and.screwdriver")
                }

            SettingsView()
                .tabItem {
                    Label("Settings".localized, systemImage: "gearshape")
                }
        }
    }
}
