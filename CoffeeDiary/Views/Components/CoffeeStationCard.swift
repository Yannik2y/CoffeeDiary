import SwiftUI
import SwiftData

struct CoffeeStationCard: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Machine.name) private var machines: [Machine]
    @Query(sort: \Grinder.name) private var grinders: [Grinder]
    @Query(sort: \Brewer.name) private var brewers: [Brewer]

    var onLogEspresso: () -> Void
    var onLogFilter: () -> Void
    /// Fallback when the setup has neither a machine nor a brewer (opens the style picker).
    var onNewBrew: () -> Void = {}
    /// Equipment filters of the brew list; the station toggles them from the tile menus.
    var machineFilterId: Binding<UUID?> = .constant(nil)
    var grinderFilterId: Binding<UUID?> = .constant(nil)
    var embeddedInList: Bool = false

    @State private var editingMachine: Machine?
    @State private var editingGrinder: Grinder?
    @State private var showingMachineForm = false
    @State private var showingGrinderForm = false

    private var activeMachine: Machine? {
        machines.first(where: \.isActive) ?? machines.first
    }

    private var activeGrinder: Grinder? {
        grinders.first(where: \.isActive) ?? grinders.first
    }

    private var canLogEspresso: Bool { activeMachine != nil }
    private var canLogFilter: Bool { !brewers.isEmpty }

    var body: some View {
        if activeMachine != nil || activeGrinder != nil {
            VStack(alignment: .leading, spacing: 14) {
                Text("Coffee Station".localized)
                    .font(.headline)

                HStack(alignment: .top, spacing: 12) {
                    machineSlot
                    grinderSlot
                }

                actionRow
            }
            .padding(16)
            .cardStyle(cornerRadius: 20)
            .padding(.horizontal, embeddedInList ? 0 : 20)
            .sheet(item: $editingMachine) { machine in
                MachineFormView(machine: machine) { updated in
                    BrewStore.shared.applyActiveMachineSelection(updated, isActive: updated.isActive, allMachines: machines)
                    ErrorHandler.save(modelContext, errorMessage: "Failed to save machine. Please try again.".localized)
                }
            }
            .sheet(item: $editingGrinder) { grinder in
                GrinderFormView(grinder: grinder) { updated in
                    BrewStore.shared.applyActiveGrinderSelection(updated, isActive: updated.isActive, allGrinders: grinders)
                    ErrorHandler.save(modelContext, errorMessage: "Failed to save grinder. Please try again.".localized)
                }
            }
            .sheet(isPresented: $showingMachineForm) {
                MachineFormView { machine in
                    modelContext.insert(machine)
                    BrewStore.shared.applyActiveMachineSelection(
                        machine,
                        isActive: machine.isActive || machines.isEmpty,
                        allMachines: machines + [machine]
                    )
                    ErrorHandler.save(modelContext, errorMessage: "Failed to save machine. Please try again.".localized)
                }
            }
            .sheet(isPresented: $showingGrinderForm) {
                GrinderFormView { grinder in
                    modelContext.insert(grinder)
                    BrewStore.shared.applyActiveGrinderSelection(
                        grinder,
                        isActive: grinder.isActive || grinders.isEmpty,
                        allGrinders: grinders + [grinder]
                    )
                    ErrorHandler.save(modelContext, errorMessage: "Failed to save grinder. Please try again.".localized)
                }
            }
        }
    }

    // MARK: Actions

    /// Mirrors the setup: espresso needs a machine, filter needs a brewer.
    /// A single action fills the width; with both, espresso is the primary one.
    @ViewBuilder
    private var actionRow: some View {
        HStack(spacing: 10) {
            if canLogEspresso {
                StationActionButton(
                    title: "Log Espresso".localized,
                    symbol: "cup.and.saucer.fill",
                    prominent: true,
                    action: onLogEspresso
                )
                .accessibilityIdentifier("stationLogEspressoButton")
            }

            if canLogFilter {
                StationActionButton(
                    title: "Log Filter".localized,
                    symbol: "drop.fill",
                    prominent: !canLogEspresso,
                    action: onLogFilter
                )
                .accessibilityIdentifier("stationLogFilterButton")
            }

            if !canLogEspresso && !canLogFilter {
                StationActionButton(
                    title: "New Brew".localized,
                    symbol: "plus.circle.fill",
                    prominent: true,
                    action: onNewBrew
                )
                .accessibilityIdentifier("stationNewBrewButton")
            }
        }
        .controlSize(.large)
        .tint(Color.accentColor)
    }

    // MARK: Slots

    @ViewBuilder
    private var machineSlot: some View {
        if let machine = activeMachine {
            let isFiltered = machineFilterId.wrappedValue == machine.id
            Menu {
                Button {
                    editingMachine = machine
                } label: {
                    Label("Edit".localized, systemImage: "pencil")
                }

                Button {
                    machineFilterId.wrappedValue = isFiltered ? nil : machine.id
                } label: {
                    if isFiltered {
                        Label("Remove Machine Filter".localized, systemImage: "line.3.horizontal.decrease.circle.fill")
                    } else {
                        Label("Show Brews With This Machine".localized, systemImage: "line.3.horizontal.decrease.circle")
                    }
                }

                let others = machines.filter { $0.id != machine.id }
                if !others.isEmpty {
                    Section("Switch Machine".localized) {
                        ForEach(others) { other in
                            Button(other.name) { activate(other) }
                        }
                    }
                }

                Button {
                    showingMachineForm = true
                } label: {
                    Label("Add Machine".localized, systemImage: "plus")
                }
            } label: {
                StationTile(
                    title: machine.name,
                    subtitle: equipmentSubtitle(brand: machine.brand, model: machine.model, fallback: "Machine".localized),
                    photoData: machine.displayPhotoData,
                    silhouette: machine.silhouette,
                    isFiltering: isFiltered
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\("Machine".localized): \(machine.name), \(machine.brand ?? "")")
            .accessibilityValue(isFiltered ? "Filters active".localized : "")
            .accessibilityIdentifier("stationMachineTile")
        } else {
            Button {
                showingMachineForm = true
            } label: {
                EmptyStationTile(title: "Add Machine".localized, silhouette: .machineCompact)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("stationAddMachineTile")
        }
    }

    @ViewBuilder
    private var grinderSlot: some View {
        if let grinder = activeGrinder {
            let isFiltered = grinderFilterId.wrappedValue == grinder.id
            Menu {
                Button {
                    editingGrinder = grinder
                } label: {
                    Label("Edit".localized, systemImage: "pencil")
                }

                Button {
                    grinderFilterId.wrappedValue = isFiltered ? nil : grinder.id
                } label: {
                    if isFiltered {
                        Label("Remove Grinder Filter".localized, systemImage: "line.3.horizontal.decrease.circle.fill")
                    } else {
                        Label("Show Brews With This Grinder".localized, systemImage: "line.3.horizontal.decrease.circle")
                    }
                }

                let others = grinders.filter { $0.id != grinder.id }
                if !others.isEmpty {
                    Section("Switch Grinder".localized) {
                        ForEach(others) { other in
                            Button(other.name) { activate(other) }
                        }
                    }
                }

                Button {
                    showingGrinderForm = true
                } label: {
                    Label("Add Grinder".localized, systemImage: "plus")
                }
            } label: {
                StationTile(
                    title: grinder.name,
                    subtitle: equipmentSubtitle(brand: grinder.brand, model: grinder.model, fallback: "Grinder".localized),
                    photoData: grinder.displayPhotoData,
                    silhouette: grinder.silhouette,
                    isFiltering: isFiltered
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\("Grinder".localized): \(grinder.name), \(grinder.brand ?? "")")
            .accessibilityValue(isFiltered ? "Filters active".localized : "")
            .accessibilityIdentifier("stationGrinderTile")
        } else {
            Button {
                showingGrinderForm = true
            } label: {
                EmptyStationTile(title: "Add Grinder".localized, silhouette: .grinderHopper)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("stationAddGrinderTile")
        }
    }

    private func equipmentSubtitle(brand: String?, model: String?, fallback: String) -> String {
        let parts = [brand, model].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? fallback : parts.joined(separator: " ")
    }

    private func activate(_ machine: Machine) {
        BrewStore.shared.setActiveMachine(machine, allMachines: machines)
        ErrorHandler.save(modelContext, errorMessage: "Failed to save machine. Please try again.".localized)
    }

    private func activate(_ grinder: Grinder) {
        BrewStore.shared.setActiveGrinder(grinder, allGrinders: grinders)
        ErrorHandler.save(modelContext, errorMessage: "Failed to save grinder. Please try again.".localized)
    }
}

// MARK: - Tiles

private struct StationActionButton: View {
    let title: String
    let symbol: String
    let prominent: Bool
    let action: () -> Void

    var body: some View {
        if prominent {
            Button(action: action) { label }
                .buttonStyle(.borderedProminent)
        } else {
            Button(action: action) { label }
                .buttonStyle(.bordered)
        }
    }

    private var label: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .symbolRenderingMode(.monochrome)
                .imageScale(.medium)
            Text(title)
        }
        .font(.subheadline.weight(.semibold))
        .frame(maxWidth: .infinity)
    }
}

struct StationTile: View {
    let title: String
    let subtitle: String
    let photoData: Data?
    let silhouette: EquipmentSilhouette
    var isFiltering: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            EquipmentVisual(photoData: photoData, silhouette: silhouette, cornerRadius: 16)
                .aspectRatio(1, contentMode: .fit)
                .overlay(alignment: .topTrailing) {
                    if isFiltering {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.white, Color.accentColor)
                            .padding(6)
                            .accessibilityHidden(true)
                    }
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

struct EmptyStationTile: View {
    let title: String
    let silhouette: EquipmentSilhouette

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.secondary.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                EquipmentSilhouetteView(silhouette: silhouette, tint: Color.secondary.opacity(0.35))
                    .padding(14)
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
            }
            .aspectRatio(1, contentMode: .fit)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .lineLimit(1)
                Text("Tap to set up".localized)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}
