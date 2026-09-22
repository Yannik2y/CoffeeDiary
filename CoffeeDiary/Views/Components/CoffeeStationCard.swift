import SwiftUI
import SwiftData

struct CoffeeStationCard: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Machine.name) private var machines: [Machine]
    @Query(sort: \Grinder.name) private var grinders: [Grinder]

    var onLogEspresso: () -> Void
    var onLogFilter: () -> Void
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

    var body: some View {
        if activeMachine != nil || activeGrinder != nil {
            VStack(alignment: .leading, spacing: 14) {
                Text("Coffee Station".localized)
                    .font(.headline)

                HStack(alignment: .top, spacing: 12) {
                    machineSlot
                    grinderSlot
                }

                HStack(spacing: 10) {
                    Button(action: onLogEspresso) {
                        Label("Espresso".localized, systemImage: "cup.and.saucer.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.accentColor)

                    Button(action: onLogFilter) {
                        Label("Filter".localized, systemImage: "drop.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.accentColor)
                }
                .controlSize(.regular)
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

    // MARK: Slots

    @ViewBuilder
    private var machineSlot: some View {
        if let machine = activeMachine {
            Menu {
                Button {
                    editingMachine = machine
                } label: {
                    Label("Edit".localized, systemImage: "pencil")
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
                    subtitle: machine.brand ?? machine.model ?? "Machine".localized,
                    photoData: machine.displayPhotoData,
                    silhouette: machine.silhouette
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\("Machine".localized): \(machine.name), \(machine.brand ?? "")")
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
            Menu {
                Button {
                    editingGrinder = grinder
                } label: {
                    Label("Edit".localized, systemImage: "pencil")
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
                    subtitle: grinderSubtitle(grinder),
                    photoData: grinder.displayPhotoData,
                    silhouette: grinder.silhouette
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\("Grinder".localized): \(grinder.name), \(grinder.brand ?? "")")
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

    private func grinderSubtitle(_ grinder: Grinder) -> String {
        let parts = [grinder.brand, grinder.model].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? "Grinder".localized : parts.joined(separator: " ")
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

struct StationTile: View {
    let title: String
    let subtitle: String
    let photoData: Data?
    let silhouette: EquipmentSilhouette

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            EquipmentVisual(photoData: photoData, silhouette: silhouette, cornerRadius: 16)
                .aspectRatio(1, contentMode: .fit)

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
