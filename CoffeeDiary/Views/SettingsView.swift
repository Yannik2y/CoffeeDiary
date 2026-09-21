import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BrewEntry.createdAt, order: .reverse) private var brews: [BrewEntry]
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true

    @State private var showingEspressoConfig = false
    @State private var showingFilterConfig = false
    @State private var showingAbout = false
    @State private var exportURL: URL?
    @State private var showingExporter = false
    @State private var exportErrorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                SyncStatusSection()

                Section("Flows".localized) {
                    Button {
                        showingEspressoConfig = true
                    } label: {
                        Label("Espresso Flow Settings".localized, systemImage: "cup.and.saucer")
                    }
                    Button {
                        showingFilterConfig = true
                    } label: {
                        Label("Filter Flow Settings".localized, systemImage: "drop.fill")
                    }
                }

                Section("Data".localized) {
                    Button {
                        exportData(format: .json)
                    } label: {
                        Label("Export as JSON".localized, systemImage: "square.and.arrow.up")
                    }
                    Button {
                        exportData(format: .csv)
                    } label: {
                        Label("Export as CSV".localized, systemImage: "tablecells")
                    }
                }

                Section("App".localized) {
                    Button {
                        showingAbout = true
                    } label: {
                        Label("About".localized, systemImage: "info.circle")
                    }
                    Button("Reset Onboarding".localized, role: .destructive) {
                        hasCompletedOnboarding = false
                    }
                }
            }
            .navigationTitle("Settings".localized)
            .sheet(isPresented: $showingEspressoConfig) {
                FlowConfigurationView(flowType: .espresso)
            }
            .sheet(isPresented: $showingFilterConfig) {
                FlowConfigurationView(flowType: .filter)
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .sheet(isPresented: $showingExporter, onDismiss: {
                if let exportURL {
                    try? FileManager.default.removeItem(at: exportURL)
                    self.exportURL = nil
                }
            }) {
                if let exportURL {
                    ShareSheet(items: [exportURL])
                }
            }
            .alert("Error".localized, isPresented: Binding(
                get: { exportErrorMessage != nil },
                set: { if !$0 { exportErrorMessage = nil } }
            )) {
                Button("OK".localized, role: .cancel) { exportErrorMessage = nil }
            } message: {
                if let exportErrorMessage {
                    Text(exportErrorMessage)
                }
            }
            .errorAlert()
        }
    }

    private enum ExportFormat { case json, csv }

    private func exportData(format: ExportFormat) {
        let data: Data?
        let filename: String
        switch format {
        case .json:
            data = BrewExportService.exportJSON(brews: brews)
            filename = "coffee-diary-export.json"
        case .csv:
            data = BrewExportService.exportCSV(brews: brews).data(using: .utf8)
            filename = "coffee-diary-export.csv"
        }
        guard let data else {
            exportErrorMessage = "Export failed. Please try again.".localized
            return
        }
        do {
            let url = try BrewExportService.writeTemporaryFile(data: data, preferredName: filename)
            exportURL = url
            showingExporter = true
        } catch {
            exportErrorMessage = "Could not write export file.".localized
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
