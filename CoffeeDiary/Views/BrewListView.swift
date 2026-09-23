import SwiftUI
import SwiftData

struct BrewListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Query(sort: \BrewEntry.createdAt, order: .reverse)
    private var brews: [BrewEntry]
    @Query(sort: \Machine.name) private var machines: [Machine]
    @Query(sort: \Grinder.name) private var grinders: [Grinder]
    
    @State private var listViewModel = BrewListViewModel()
    @State private var selectedBrewId: UUID?
    @State private var showingAdd = false
    @State private var searchText: String = ""
    @State private var debouncedSearchText: String = ""
    @State private var searchDebounceWorkItem: DispatchWorkItem? = nil
    @State private var filterShot: ShotType? = nil
    @State private var filterBrewStyle: BrewFlowType? = nil
    @State private var showingFilters: Bool = false
    @State private var filterStartDate: Date? = nil
    @State private var filterEndDate: Date? = nil
    @State private var filterMinRatio: Double? = nil
    @State private var filterMaxRatio: Double? = nil
    @State private var filterMinRating: Int? = nil
    @State private var filterMachineId: UUID? = nil
    @State private var filterGrinderId: UUID? = nil
    @State private var showingFlowPicker: Bool = false
    @State private var showingEspressoFlow: Bool = false
    @State private var showingFilterFlow: Bool = false
    @State private var showingEspressoConfig: Bool = false
    @State private var showingFilterConfig: Bool = false
    @State private var showingOverflowMenu: Bool = false
    /// Deferred sheet destination after overflow menu dismisses (avoids sheet-from-sheet race).
    @State private var pendingOverflowDestination: OverflowDestination? = nil

    private enum OverflowDestination {
        case filters, espressoConfig, filterConfig
    }

    private let shotFilterAllTag = -1
    private let brewStyleFilterAllTag = -1
    private let brewStyleEspressoTag = 0
    private let brewStyleFilterTag = 1
    private static let filterFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    private var filterDateFormatter: DateFormatter { Self.filterFormatter }
    
    private var dialInSuggestion: DialInSuggestion? {
        guard let bean = brews.first?.bean ?? brews.compactMap(\.bean).first else { return nil }
        return DialInAssistant.suggestion(for: bean, in: brews)
    }

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                NavigationSplitView {
                    listNavigationContent
                } detail: {
                    if let id = selectedBrewId,
                       let entry = listViewModel.cachedFilteredBrews.first(where: { $0.id == id }) {
                        BrewDetailView(entry: entry)
                    } else {
                        ContentUnavailableView("Select a brew".localized, systemImage: "cup.and.saucer")
                    }
                }
            } else {
                NavigationStack {
                    listNavigationContent
                        .navigationDestination(for: UUID.self) { id in
                            BrewDetailViewWrapper(brewId: id, allBrews: brews)
                                .transaction { $0.animation = nil }
                        }
                }
            }
        }
    }

    @ViewBuilder
    private var listNavigationContent: some View {
        contentBody
            .navigationTitle("Coffee Diary".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(AppTheme.subtleBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Picker("Brew Style".localized, selection: brewStyleFilterBinding) {
                            Text("All".localized).tag(brewStyleFilterAllTag)
                            Text("Espresso".localized).tag(brewStyleEspressoTag)
                            Text("Filter".localized).tag(brewStyleFilterTag)
                        }
                        Picker("Shot Filter".localized, selection: shotFilterBinding) {
                            Text("All".localized).tag(shotFilterAllTag)
                            ForEach(ShotType.allCases) { type in
                                Text(type.displayName).tag(type.rawValue)
                            }
                        }
                        if !machines.isEmpty {
                            Picker("Machine".localized, selection: $filterMachineId) {
                                Text("All".localized).tag(UUID?.none)
                                ForEach(machines) { machine in
                                    Text(machine.name).tag(Optional(machine.id))
                                }
                            }
                        }
                        if !grinders.isEmpty {
                            Picker("Grinder".localized, selection: $filterGrinderId) {
                                Text("All".localized).tag(UUID?.none)
                                ForEach(grinders) { grinder in
                                    Text(grinder.name).tag(Optional(grinder.id))
                                }
                            }
                        }
                        Button("More Filters".localized, systemImage: "slider.horizontal.3") {
                            showingFilters = true
                        }
                        if hasActiveFilters {
                            Button("Clear All".localized, systemImage: "xmark.circle", role: .destructive) {
                                clearAllFilters()
                            }
                        }
                    } label: {
                        Image(systemName: hasActiveFilters
                              ? "line.3.horizontal.decrease.circle.fill"
                              : "line.3.horizontal.decrease.circle")
                    }
                    .accessibilityLabel("Filters".localized)
                    .accessibilityValue(hasActiveFilters ? "Filters active".localized : "No filters".localized)

                    Button {
                        showingFlowPicker = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                    .accessibilityLabel("New Entry".localized)
                    .accessibilityIdentifier("toolbarNewEntryButton")
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            showingOverflowMenu.toggle()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("More actions".localized)
                }
            }
            .sheet(isPresented: $showingOverflowMenu, onDismiss: {
                guard let destination = pendingOverflowDestination else { return }
                pendingOverflowDestination = nil
                DispatchQueue.main.async {
                    switch destination {
                    case .filters: showingFilters = true
                    case .espressoConfig: showingEspressoConfig = true
                    case .filterConfig: showingFilterConfig = true
                    }
                }
            }) {
                OverflowMenuView(
                    showAdvancedFilters: { pendingOverflowDestination = .filters },
                    showEspressoConfig: { pendingOverflowDestination = .espressoConfig },
                    showFilterConfig: { pendingOverflowDestination = .filterConfig }
                )
            }
            .searchable(text: $searchText, prompt: Text("Search coffee, bean, or roaster".localized))
            .background(AppTheme.subtleBackground)
            .onChange(of: searchText) { _, newValue in
                searchDebounceWorkItem?.cancel()
                let work = DispatchWorkItem { debouncedSearchText = newValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                searchDebounceWorkItem = work
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: work)
            }
            .onDisappear {
                searchDebounceWorkItem?.cancel()
                searchDebounceWorkItem = nil
            }
            .confirmationDialog("Create entry".localized, isPresented: $showingFlowPicker, titleVisibility: .visible) {
                Button("Espresso".localized) { showingEspressoFlow = true }
                    .accessibilityIdentifier("flowOptionEspresso")
                Button("Filter".localized) { showingFilterFlow = true }
                    .accessibilityIdentifier("flowOptionFilter")
                Button("Manual form".localized) { showingAdd = true }
                    .accessibilityIdentifier("flowOptionManual")
                Button("Cancel".localized, role: .cancel) {}
            }
            .sheet(isPresented: $showingAdd) { BrewFormView() }
            .sheet(isPresented: $showingEspressoFlow) { BrewEntryFlowView(flow: .espresso) }
            .sheet(isPresented: $showingFilterFlow) { BrewEntryFlowView(flow: .filter) }
            .sheet(isPresented: $showingEspressoConfig) {
                FlowConfigurationView(flowType: .espresso)
            }
            .sheet(isPresented: $showingFilterConfig) {
                FlowConfigurationView(flowType: .filter)
            }
            .sheet(isPresented: $showingFilters) {
                BrewFilterSheet(
                    filterStartDate: $filterStartDate,
                    filterEndDate: $filterEndDate,
                    filterMinRatio: $filterMinRatio,
                    filterMaxRatio: $filterMaxRatio,
                    filterMinRating: $filterMinRating,
                    isPresented: $showingFilters
                )
            }
            .onAppear {
                updateCachedFilteredBrews()
            }
            .onChange(of: filterCriteria) { _, _ in
                updateCachedFilteredBrews()
            }
            .onChange(of: brews.count) { _, _ in
                updateCachedFilteredBrews()
            }
            .onChange(of: showingAdd) { _, isShowing in
                if !isShowing { updateCachedFilteredBrews() }
            }
            .onChange(of: showingEspressoFlow) { _, isShowing in
                if !isShowing { updateCachedFilteredBrews() }
            }
            .onChange(of: showingFilterFlow) { _, isShowing in
                if !isShowing { updateCachedFilteredBrews() }
            }
            .errorAlert()
    }

    private var filterCriteria: BrewFilterCriteria {
        BrewFilterCriteria(
            searchText: debouncedSearchText,
            shotType: filterShot,
            brewStyle: filterBrewStyle,
            startDate: filterStartDate,
            endDate: filterEndDate,
            minRatio: filterMinRatio,
            maxRatio: filterMaxRatio,
            minRating: filterMinRating,
            machineId: filterMachineId,
            grinderId: filterGrinderId
        )
    }

    private func updateCachedFilteredBrews() {
        listViewModel.updateFilteredBrews(from: brews, criteria: filterCriteria)
        if let selectedBrewId,
           !listViewModel.cachedFilteredBrews.contains(where: { $0.id == selectedBrewId }) {
            self.selectedBrewId = nil
        }
    }
    
    private func delete(at offsets: IndexSet) {
        Task { @MainActor in
            for index in offsets {
                let entry = listViewModel.cachedFilteredBrews[index]
                modelContext.delete(entry)
            }
            await ErrorHandler.saveAsync(modelContext, errorMessage: "Failed to delete brew entry. Please try again.".localized)
        }
    }
    
    private func deleteEntries(_ entries: [BrewEntry]) {
        Task { @MainActor in
            for entry in entries {
                modelContext.delete(entry)
            }
            await ErrorHandler.saveAsync(modelContext, errorMessage: "Failed to delete brew entries. Please try again.".localized)
        }
    }
    
    private func duplicate(_ entry: BrewEntry) {
        Task { @MainActor in
            _ = BrewStore.shared.duplicate(entry, in: modelContext)
            _ = await BrewStore.shared.saveAsync(modelContext, errorMessage: "Failed to duplicate brew entry. Please try again.".localized)
        }
    }
    
    private func toggleFavorite(_ entry: BrewEntry) {
        Task { @MainActor in
            entry.isFavorite.toggle()
            await ErrorHandler.saveAsync(modelContext, errorMessage: "Failed to update favorite status. Please try again.".localized)
        }
    }
    
    private var contentBody: some View {
        Group {
            if listViewModel.cachedFilteredBrews.isEmpty && brews.isEmpty {
                emptyStateView
            } else {
                populatedListView
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(emptyStateGradient)
                    .frame(width: 120, height: 120)
                    .shadow(color: AppTheme.accent.opacity(0.12), radius: 16, x: 0, y: 8)
                Image(systemName: "cup.and.saucer.fill")
                    .font(.largeTitle.weight(.medium))
                    .imageScale(.large)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.accent, AppTheme.accentSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            VStack(spacing: 8) {
                Text("No brews yet".localized)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Track your extractions with dose, yield, time and notes.".localized)
                    .font(.system(.body, design: .rounded, weight: .regular))
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Button {
                showingFlowPicker = true
            } label: {
                Label("Add your first brew".localized, systemImage: "plus.circle.fill")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(AppTheme.accent)
            .accessibilityIdentifier("emptyStateAddButton")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    private var emptyStateGradient: LinearGradient {
        LinearGradient(
            colors: [
                AppTheme.accentSecondary.opacity(0.3),
                AppTheme.accentSecondary.opacity(0.15),
                AppTheme.cardBackground
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var populatedListView: some View {
        List {
            Section {
                SyncStatusBanner(embeddedInList: true)
                CoffeeStationCard(
                    onLogEspresso: { showingEspressoFlow = true },
                    onLogFilter: { showingFilterFlow = true },
                    onNewBrew: { showingFlowPicker = true },
                    machineFilterId: $filterMachineId,
                    grinderFilterId: $filterGrinderId,
                    embeddedInList: true
                )
                if let suggestion = dialInSuggestion {
                    DialInBanner(suggestion: suggestion, embeddedInList: true)
                }
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)

            if hasActiveFilters {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            filterChips
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 12, bottom: 4, trailing: 12))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }

            if brews.isEmpty == false && listViewModel.cachedFilteredBrews.isEmpty {
                Section {
                    filteredEmptyStateView
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(listViewModel.cachedFilteredBrews, id: \.id) { entry in
                        Group {
                            if horizontalSizeClass == .regular {
                                Button {
                                    selectedBrewId = entry.id
                                } label: {
                                    BrewRow(entry: entry)
                                }
                                .buttonStyle(.plain)
                            } else {
                                NavigationLink(value: entry.id) {
                                    BrewRow(entry: entry)
                                }
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                toggleFavorite(entry)
                            } label: {
                                Label(entry.isFavorite ? "Unfavorite".localized : "Favorite".localized, systemImage: entry.isFavorite ? "star.slash" : "star")
                            }
                            .tint(.yellow)
                        }
                        .swipeActions {
                            Button {
                                duplicate(entry)
                            } label: {
                                Label("Duplicate".localized, systemImage: "doc.on.doc")
                            }
                            .tint(.blue)
                            Button(role: .destructive) {
                                deleteEntries([entry])
                            } label: {
                                Label("Delete".localized, systemImage: "trash")
                            }
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                    }
                    .onDelete(perform: delete)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .contentMargins(.top, 0, for: .scrollContent)
        .background(AppTheme.subtleBackground)
    }

    private var filteredEmptyStateView: some View {
        ContentUnavailableView {
            Label("No brews match your filters".localized, systemImage: "line.3.horizontal.decrease.circle")
        } description: {
            Text("Try adjusting or clearing your filters.".localized)
        } actions: {
            Button("Clear All Filters".localized) {
                clearAllFilters()
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var shotFilterBinding: Binding<Int> {
        Binding(
            get: { filterShot?.rawValue ?? shotFilterAllTag },
            set: { newValue in
                filterShot = newValue == shotFilterAllTag ? nil : ShotType(rawValue: newValue)
            }
        )
    }
    
    private var brewStyleFilterBinding: Binding<Int> {
        Binding(
            get: {
                guard let style = filterBrewStyle else { return brewStyleFilterAllTag }
                return style == .espresso ? brewStyleEspressoTag : brewStyleFilterTag
            },
            set: { newValue in
                switch newValue {
                case brewStyleEspressoTag: filterBrewStyle = .espresso
                case brewStyleFilterTag: filterBrewStyle = .filter
                default: filterBrewStyle = nil
                }
            }
        )
    }
    
    private var hasActiveFilters: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        filterShot != nil ||
        filterBrewStyle != nil ||
        filterStartDate != nil ||
        filterEndDate != nil ||
        (filterMinRatio ?? 0) > 0 ||
        (filterMaxRatio ?? 0) > 0 ||
        (filterMinRating ?? 0) > 0 ||
        filterMachineId != nil ||
        filterGrinderId != nil
    }
    
    @ViewBuilder
    private var filterChips: some View {
        if let shot = filterShot {
            FilterChip(text: "Shot %@".localized(with: shot.displayName)) {
                filterShot = nil
            }
        }
        if let style = filterBrewStyle {
            FilterChip(text: style.title) {
                filterBrewStyle = nil
            }
        }
        if let machineId = filterMachineId {
            let name = machines.first { $0.id == machineId }?.name ?? "Machine".localized
            FilterChip(text: "Machine: %@".localized(with: name)) {
                filterMachineId = nil
            }
        }
        if let grinderId = filterGrinderId {
            let name = grinders.first { $0.id == grinderId }?.name ?? "Grinder".localized
            FilterChip(text: "Grinder: %@".localized(with: name)) {
                filterGrinderId = nil
            }
        }
        if let start = filterStartDate {
            FilterChip(text: "From %@".localized(with: filterDateFormatter.string(from: start))) {
                filterStartDate = nil
            }
        }
        if let end = filterEndDate {
            FilterChip(text: "To %@".localized(with: filterDateFormatter.string(from: end))) {
                filterEndDate = nil
            }
        }
        if let minR = filterMinRatio, let maxR = filterMaxRatio, maxR > 0 {
            FilterChip(text: "Ratio %@–%@".localized(with: formatRatio(minR), formatRatio(maxR))) {
                filterMinRatio = nil
                filterMaxRatio = nil
            }
        } else if let minR = filterMinRatio {
            FilterChip(text: "Ratio ≥%@".localized(with: formatRatio(minR))) {
                filterMinRatio = nil
            }
        } else if let maxR = filterMaxRatio, maxR > 0 {
            FilterChip(text: "Ratio ≤%@".localized(with: formatRatio(maxR))) {
                filterMaxRatio = nil
            }
        }
        if let minRating = filterMinRating, minRating > 0 {
            FilterChip(text: "Rating ≥ %d".localized(with: minRating)) {
                filterMinRating = nil
            }
        }
    }
    
    private func clearAllFilters() {
        searchText = ""
        debouncedSearchText = ""
        searchDebounceWorkItem?.cancel()
        filterShot = nil
        filterBrewStyle = nil
        filterStartDate = nil
        filterEndDate = nil
        filterMinRatio = nil
        filterMaxRatio = nil
        filterMinRating = nil
        filterMachineId = nil
        filterGrinderId = nil
    }
    
    private func formatRatio(_ value: Double) -> String {
        String(format: "%.1f", value)
    }
    
}

private struct OverflowMenuView: View {
    @Environment(\.dismiss) private var dismiss

    let showAdvancedFilters: () -> Void
    let showEspressoConfig: () -> Void
    let showFilterConfig: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section("Quick Actions".localized) {
                    Button {
                        showAdvancedFilters()
                        dismiss()
                    } label: {
                        Label("Advanced Filters…".localized, systemImage: "line.3.horizontal.decrease.circle")
                    }
                }

                Section("Flows".localized) {
                    Button {
                        showEspressoConfig()
                        dismiss()
                    } label: {
                        Label("Espresso Flow Settings".localized, systemImage: "cup.and.saucer")
                    }
                    Button {
                        showFilterConfig()
                        dismiss()
                    } label: {
                        Label("Filter Flow Settings".localized, systemImage: "drop.fill")
                    }
                }
            }
            .navigationTitle("More Options".localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done".localized) { dismiss() }
                }
            }
        }
    }
}

// Legacy Badge kept for compatibility
private struct Badge: View {
    let text: String
    let systemImage: String
    var body: some View {
        MetricBadge(icon: systemImage, text: text, color: AppTheme.accent)
    }
}

// Wrapper to optimize navigation destination lookup
private struct BrewDetailViewWrapper: View {
    let brewId: UUID
    let allBrews: [BrewEntry]
    
    var body: some View {
        Group {
            if let entry = allBrews.first(where: { $0.id == brewId }) {
                BrewDetailView(entry: entry)
                    .id(entry.id)
            } else {
                ContentUnavailableView("Brew not found".localized, systemImage: "cup.and.saucer")
            }
        }
    }
}


