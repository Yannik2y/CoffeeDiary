import SwiftUI
import SwiftData

struct EquipmentManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Bean.name) private var beans: [Bean]
    @Query(sort: \Grinder.name) private var grinders: [Grinder]
    @Query(sort: \Machine.name) private var machines: [Machine]
    @Query(sort: \Brewer.name) private var brewers: [Brewer]

    var embedded: Bool = false

    @State private var selectedTab: EquipmentTab = .beans
    @State private var showingBeanForm = false
    @State private var showingGrinderForm = false
    @State private var showingMachineForm = false
    @State private var showingBrewerForm = false
    @State private var editingBean: Bean?
    @State private var editingGrinder: Grinder?
    @State private var editingMachine: Machine?
    @State private var editingBrewer: Brewer?
    @State private var pendingDelete: EquipmentItem?
    @State private var confirmDelete = false

    enum EquipmentTab: String, CaseIterable {
        case beans, grinders, machines, brewers

        var title: String {
            switch self {
            case .beans: return "Beans".localized
            case .grinders: return "Grinders".localized
            case .machines: return "Machines".localized
            case .brewers: return "Brewers".localized
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Equipment".localized, selection: $selectedTab) {
                    ForEach(EquipmentTab.allCases, id: \.self) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                Group {
                    switch selectedTab {
                    case .beans:
                        equipmentList(
                            items: beans.map { EquipmentItem.bean($0) },
                            emptyTitle: "No beans yet".localized,
                            onAdd: { showingBeanForm = true },
                            onDelete: { pendingDelete = $0; confirmDelete = true },
                            onEdit: { if case .bean(let b) = $0 { editingBean = b } }
                        )
                    case .grinders:
                        equipmentList(
                            items: grinders.map { EquipmentItem.grinder($0) },
                            emptyTitle: "No grinders yet".localized,
                            onAdd: { showingGrinderForm = true },
                            onDelete: { pendingDelete = $0; confirmDelete = true },
                            onEdit: { if case .grinder(let g) = $0 { editingGrinder = g } }
                        )
                    case .machines:
                        equipmentList(
                            items: machines.map { EquipmentItem.machine($0) },
                            emptyTitle: "No machines yet".localized,
                            onAdd: { showingMachineForm = true },
                            onDelete: { pendingDelete = $0; confirmDelete = true },
                            onEdit: { if case .machine(let m) = $0 { editingMachine = m } }
                        )
                    case .brewers:
                        equipmentList(
                            items: brewers.map { EquipmentItem.brewer($0) },
                            emptyTitle: "No brewers yet".localized,
                            onAdd: { showingBrewerForm = true },
                            onDelete: { pendingDelete = $0; confirmDelete = true },
                            onEdit: { if case .brewer(let b) = $0 { editingBrewer = b } }
                        )
                    }
                }
            }
            .background(AppTheme.subtleBackground)
            .navigationTitle("Equipment".localized)
            .toolbar {
                if !embedded {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done".localized) { dismiss() }
                    }
                }
            }
            .sheet(isPresented: $showingBeanForm) {
                BeanFormView { bean in
                    modelContext.insert(bean)
                    ErrorHandler.save(modelContext, errorMessage: "Failed to save bean. Please try again.".localized)
                }
            }
            .sheet(item: $editingBean) { bean in
                BeanFormView(bean: bean) { _ in
                    ErrorHandler.save(modelContext, errorMessage: "Failed to save bean. Please try again.".localized)
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
            .sheet(item: $editingGrinder) { grinder in
                GrinderFormView(grinder: grinder) { updated in
                    BrewStore.shared.applyActiveGrinderSelection(
                        updated,
                        isActive: updated.isActive,
                        allGrinders: grinders
                    )
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
            .sheet(item: $editingMachine) { machine in
                MachineFormView(machine: machine) { updated in
                    BrewStore.shared.applyActiveMachineSelection(
                        updated,
                        isActive: updated.isActive,
                        allMachines: machines
                    )
                    ErrorHandler.save(modelContext, errorMessage: "Failed to save machine. Please try again.".localized)
                }
            }
            .sheet(isPresented: $showingBrewerForm) {
                BrewerFormView { brewer in
                    modelContext.insert(brewer)
                    ErrorHandler.save(modelContext, errorMessage: "Failed to save brewer. Please try again.".localized)
                }
            }
            .sheet(item: $editingBrewer) { brewer in
                BrewerFormView(brewer: brewer) { _ in
                    ErrorHandler.save(modelContext, errorMessage: "Failed to save brewer. Please try again.".localized)
                }
            }
            .confirmationDialog("Delete equipment?".localized, isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete".localized, role: .destructive) {
                    if let item = pendingDelete {
                        _ = BrewStore.shared.deleteEquipment(item, policy: .nullifyRelationships, in: modelContext)
                    }
                    pendingDelete = nil
                }
                Button("Cancel".localized, role: .cancel) { pendingDelete = nil }
            } message: {
                if let item = pendingDelete {
                    let count = BrewStore.shared.referencedBrewCount(for: item, in: modelContext)
                    if count > 0 {
                        Text("This item is used in %d brews. Brew history will be kept.".localized(with: count))
                    }
                }
            }
            .errorAlert()
            .onAppear {
                BrewStore.shared.reconcileActiveEquipment(machines: machines, grinders: grinders)
            }
        }
    }

    @ViewBuilder
    private func equipmentList(
        items: [EquipmentItem],
        emptyTitle: String,
        onAdd: @escaping () -> Void,
        onDelete: @escaping (EquipmentItem) -> Void,
        onEdit: @escaping (EquipmentItem) -> Void
    ) -> some View {
        if items.isEmpty {
            ContentUnavailableView {
                Label(emptyTitle, systemImage: "tray")
            } description: {
                Text("Add New".localized)
            } actions: {
                Button("Add New".localized, action: onAdd)
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.accent)
            }
        } else {
            EquipmentList(
                items: items,
                onAdd: onAdd,
                onDelete: onDelete,
                onEdit: onEdit
            )
        }
    }
}

enum EquipmentItem: Identifiable {
    case bean(Bean)
    case grinder(Grinder)
    case machine(Machine)
    case brewer(Brewer)

    var id: UUID {
        switch self {
        case .bean(let b): return b.id
        case .grinder(let g): return g.id
        case .machine(let m): return m.id
        case .brewer(let b): return b.id
        }
    }

    var name: String {
        switch self {
        case .bean(let b): return b.name
        case .grinder(let g): return g.name
        case .machine(let m): return m.name
        case .brewer(let b): return b.name
        }
    }

    var subtitle: String? {
        switch self {
        case .bean(let b):
            if let days = b.daysSinceRoast {
                return "\(b.roaster ?? b.origin ?? "") · \("Day %d since roast".localized(with: days))"
            }
            return b.roaster ?? b.origin
        case .grinder(let g):
            let parts = [g.brand, g.model].compactMap { $0 }.filter { !$0.isEmpty }
            return parts.isEmpty ? g.burrType : parts.joined(separator: " ")
        case .machine(let m):
            let parts = [m.brand, m.model].compactMap { $0 }.filter { !$0.isEmpty }
            return parts.isEmpty ? nil : parts.joined(separator: " ")
        case .brewer(let b):
            return b.style ?? b.brand
        }
    }

    var photoData: Data? {
        switch self {
        case .bean(let b): return b.displayPhotoData
        case .grinder(let g): return g.displayPhotoData
        case .machine(let m): return m.displayPhotoData
        case .brewer(let b): return b.displayPhotoData
        }
    }

    var fallbackSymbol: String {
        switch self {
        case .bean: return "leaf.fill"
        case .grinder: return "gearshape.fill"
        case .machine: return "cup.and.saucer.fill"
        case .brewer: return "drop.circle.fill"
        }
    }

    var silhouette: EquipmentSilhouette? {
        switch self {
        case .grinder(let g): return g.silhouette
        case .machine(let m): return m.silhouette
        case .bean, .brewer: return nil
        }
    }
}

private struct EquipmentList: View {
    let items: [EquipmentItem]
    let onAdd: () -> Void
    let onDelete: (EquipmentItem) -> Void
    let onEdit: (EquipmentItem) -> Void

    var body: some View {
        List {
            ForEach(items) { item in
                Button {
                    onEdit(item)
                } label: {
                    EquipmentRow(item: item)
                }
                .buttonStyle(.plain)
                .swipeActions {
                    Button(role: .destructive) {
                        onDelete(item)
                    } label: {
                        Label("Delete".localized, systemImage: "trash")
                    }
                }
            }
            Button(action: onAdd) {
                Label("Add New".localized, systemImage: "plus.circle")
                    .foregroundStyle(AppTheme.accent)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppTheme.subtleBackground)
    }
}

private struct EquipmentRow: View {
    let item: EquipmentItem

    var body: some View {
        HStack(spacing: 12) {
            EquipmentThumbnail(photoData: item.photoData, systemImage: item.fallbackSymbol, silhouette: item.silhouette)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.8))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
    }
}

private struct EquipmentThumbnail: View {
    let photoData: Data?
    let systemImage: String
    var silhouette: EquipmentSilhouette? = nil

    var body: some View {
        Group {
            if photoData != nil {
                CachedThumbnailImage(data: photoData, maxDimension: 120)
            } else if let silhouette {
                EquipmentSilhouetteView(silhouette: silhouette)
                    .padding(4)
            } else {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: 44, height: 44)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppTheme.cardBackground)
                .shadow(color: AppTheme.cardShadow.opacity(0.25), radius: 2, x: 0, y: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
