import SwiftUI

struct FlowConfigurationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var config = FlowConfiguration.load()
    let flowType: BrewFlowType

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if flowType == .espresso {
                        Toggle("Coffee Name".localized, isOn: $config.espressoCoffee)
                        Toggle("Shot Type".localized, isOn: $config.espressoShotType)
                        Toggle("Grinder Setting".localized, isOn: $config.espressoGrinder)
                        Toggle("Grinder Timer".localized, isOn: $config.espressoGrinderTimer)
                            .disabled(!config.espressoGrinder)
                        Toggle("Dose".localized, isOn: $config.espressoDose)
                        Toggle("Brew time".localized, isOn: $config.espressoTime)
                        Toggle("Pre-infusion time".localized, isOn: $config.espressoPreInfusionTime)
                            .disabled(!config.espressoTime)
                        Toggle("Brew pressure".localized, isOn: $config.espressoBrewPressure)
                        Toggle("Brewed Amount".localized, isOn: $config.espressoYield)
                        Toggle("Equipment (Bean/Grinder/Machine)".localized, isOn: $config.espressoGear)
                        Toggle("Notes".localized, isOn: $config.espressoNotes)
                        Toggle("Rating".localized, isOn: $config.espressoRating)
                        Toggle("Weather".localized, isOn: $config.espressoWeather)
                    } else {
                        Toggle("Coffee Name".localized, isOn: $config.filterCoffee)
                        Toggle("Grinder Setting".localized, isOn: $config.filterGrinder)
                        Toggle("Grinder Timer".localized, isOn: $config.filterGrinderTimer)
                            .disabled(!config.filterGrinder)
                        Toggle("Dose".localized, isOn: $config.filterDose)
                        Toggle("Brew time".localized, isOn: $config.filterTime)
                        Toggle("Brewed Amount".localized, isOn: $config.filterYield)
                        Toggle("Brewer Selection".localized, isOn: $config.filterBrewer)
                        Toggle("Bloom Details".localized, isOn: $config.filterBloom)
                        Toggle("Total Water".localized, isOn: $config.filterTotalWater)
                        Toggle("Water Temperature".localized, isOn: $config.filterWaterTemp)
                        Toggle("Equipment (Bean/Grinder)".localized, isOn: $config.filterGear)
                        Toggle("Notes".localized, isOn: $config.filterNotes)
                        Toggle("Rating".localized, isOn: $config.filterRating)
                        Toggle("Weather".localized, isOn: $config.filterWeather)
                    }
                } header: {
                    Text("Questions to Ask".localized)
                } footer: {
                    Text("Disable questions you don't want to see in the workflow".localized)
                }
            }
            .navigationTitle("Configure %@ Workflow".localized(with: flowType.title))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done".localized) {
                        config.save()
                        dismiss()
                    }
                }
            }
        }
    }
}
