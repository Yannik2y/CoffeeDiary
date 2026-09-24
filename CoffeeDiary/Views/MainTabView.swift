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
        .modifier(BottomTabBarPreferredStyle())
    }
}

/// Prefer classic bottom tabs on iPad (iOS 18+), so snapshot tests and UI stay consistent.
private struct BottomTabBarPreferredStyle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.tabViewStyle(.tabBarOnly)
        } else {
            content
        }
    }
}
