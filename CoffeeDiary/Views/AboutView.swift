import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let websiteURL = URL(string: "https://yannik2y.github.io/CoffeeDiary/")!
    private let supportURL = URL(string: "https://yannik2y.github.io/CoffeeDiary/support")!
    private let privacyURL = URL(string: "https://yannik2y.github.io/CoffeeDiary/privacy-policy")!
    private let openMeteoURL = URL(string: "https://open-meteo.com/")!
    
    private var versionText: String {
        let bundle = Bundle.main
        let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        let build = bundle.infoDictionary?["CFBundleVersion"] as? String ?? "-"
        return "Version %@ (%@)".localized(with: version, build)
    }
    
    var body: some View {
        NavigationStack {
            List {
                SyncStatusSection()

                Section("App".localized) {
                    HStack {
                        Text("Version".localized)
                        Spacer()
                        Text(versionText)
                            .foregroundStyle(.secondary)
                    }
                    Text("App about blurb".localized)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                
                Section("Resources".localized) {
                    Link(destination: websiteURL) {
                        Label("Website".localized, systemImage: "globe")
                    }
                    Link(destination: supportURL) {
                        Label("Support".localized, systemImage: "questionmark.circle")
                    }
                    Link(destination: privacyURL) {
                        Label("Privacy Policy".localized, systemImage: "lock.shield")
                    }
                }
                
                Section("Acknowledgements".localized) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Weather data provided by Open-Meteo.".localized)
                        Link("open-meteo.com", destination: openMeteoURL)
                            .font(.footnote)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("About".localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done".localized) { dismiss() }
                }
            }
        }
    }
}

