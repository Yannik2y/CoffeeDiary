import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Bean.name) private var beans: [Bean]
    @Query(sort: \Grinder.name) private var grinders: [Grinder]
    @Query(sort: \Machine.name) private var machines: [Machine]
    @Query(sort: \Brewer.name) private var brewers: [Brewer]
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    @State private var currentStep: OnboardingStep = .welcome
    @State private var showingBeanForm = false
    @State private var showingGrinderForm = false
    @State private var showingMachineForm = false
    @State private var showingBrewerForm = false
    
    enum OnboardingStep: Int, CaseIterable {
        case welcome = 0
        case bean = 1
        case grinder = 2
        case machine = 3
        case brewer = 4
        case complete = 5
        
        var title: String {
            switch self {
            case .welcome: return "Welcome to Coffee Diary".localized
            case .bean: return "Add Your First Bean".localized
            case .grinder: return "Add Your Grinder".localized
            case .machine: return "Add Your Machine".localized
            case .brewer: return "Add Your Brewer".localized
            case .complete: return "You're All Set!".localized
            }
        }
        
        var description: String {
            switch self {
            case .welcome:
                return "Let's set up your coffee equipment. This will help you track your brews more effectively.".localized
            case .bean:
                return "Start by adding at least one coffee bean. You can add more later in settings.".localized
            case .grinder:
                return "Add your grinder to track grind settings. You can skip this and add it later.".localized
            case .machine:
                return "Add your espresso machine. You can skip this and add it later.".localized
            case .brewer:
                return "Add your filter brewer (V60, Chemex, etc.). You can skip this and add it later.".localized
            case .complete:
                return "You're ready to start tracking your coffee journey!".localized
            }
        }
        
        var icon: String {
            switch self {
            case .welcome: return "cup.and.saucer.fill"
            case .bean: return "leaf.fill"
            case .grinder: return "gearshape.fill"
            case .machine: return "cup.and.saucer.fill"
            case .brewer: return "drop.circle.fill"
            case .complete: return "checkmark.circle.fill"
            }
        }
    }
    
    var body: some View {
        ZStack {
            AppTheme.subtleBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator
                if currentStep != .welcome && currentStep != .complete {
                    progressView
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                }
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            AppTheme.accentSecondary.opacity(0.25),
                                            AppTheme.cardBackground
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: currentStep.icon)
                                .font(.system(size: 50, weight: .medium))
                                .foregroundStyle(AppTheme.accent)
                                .imageScale(.large)
                        }
                        .padding(.top, currentStep == .welcome ? 60 : 40)
                        
                        // Title and description
                        VStack(spacing: 12) {
                            Text(currentStep.title)
                                .font(.largeTitle.weight(.bold))
                                .foregroundStyle(AppTheme.textPrimary)
                                .multilineTextAlignment(.center)
                            
                            Text(currentStep.description)
                                .font(.body)
                                .foregroundStyle(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        
                        // Step-specific content
                        stepContent
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                    }
                    .padding(.bottom, 40)
                }
                
                // Action buttons
                actionButtons
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showingBeanForm) {
            BeanFormView { bean in
                modelContext.insert(bean)
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
        .sheet(isPresented: $showingBrewerForm) {
            BrewerFormView { brewer in
                modelContext.insert(brewer)
                ErrorHandler.save(modelContext, errorMessage: "Failed to save brewer. Please try again.".localized)
            }
        }
        .onChange(of: beans.count) { oldCount, newCount in
            // Auto-advance only when going from 0 to 1 (first bean added)
            if currentStep == .bean && oldCount == 0 && newCount > 0 {
                nextStep()
            }
        }
    }
    
    private var progressView: some View {
        HStack(spacing: 8) {
            ForEach(1..<OnboardingStep.complete.rawValue, id: \.self) { step in
                RoundedRectangle(cornerRadius: 2)
                    .fill(step <= currentStep.rawValue ? AppTheme.accent : AppTheme.textSecondary.opacity(0.2))
                    .frame(height: 4)
            }
        }
    }
    
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .welcome:
            EmptyView()
        case .bean:
            beanStepContent
        case .grinder:
            grinderStepContent
        case .machine:
            machineStepContent
        case .brewer:
            brewerStepContent
        case .complete:
            completeStepContent
        }
    }
    
    private var beanStepContent: some View {
        VStack(spacing: 16) {
            if beans.isEmpty {
                Button {
                    showingBeanForm = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                        Text("Add Bean".localized)
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(beans.prefix(3)) { bean in
                        HStack {
                            Image(systemName: "leaf.fill")
                                .foregroundStyle(AppTheme.accent)
                            Text(bean.name)
                                .foregroundStyle(AppTheme.textPrimary)
                            Spacer()
                        }
                        .padding()
                        .background(AppTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    
                    if beans.count > 3 {
                        Text("+ %d more".localized(with: beans.count - 3))
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    
                    Button {
                        showingBeanForm = true
                    } label: {
                        Text("Add Another Bean".localized)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.accent)
                    }
                    .padding(.top, 8)
                }
            }
        }
    }
    
    private var grinderStepContent: some View {
        equipmentStepContent(
            items: grinders,
            icon: "gearshape.fill",
            itemName: { $0.name },
            addButtonText: "Add Grinder".localized,
            addAnotherText: "Add Another Grinder".localized,
            onAdd: { showingGrinderForm = true }
        )
    }
    
    private var machineStepContent: some View {
        equipmentStepContent(
            items: machines,
            icon: "cup.and.saucer.fill",
            itemName: { $0.name },
            addButtonText: "Add Machine".localized,
            addAnotherText: "Add Another Machine".localized,
            onAdd: { showingMachineForm = true }
        )
    }
    
    private var brewerStepContent: some View {
        equipmentStepContent(
            items: brewers,
            icon: "drop.circle.fill",
            itemName: { $0.name },
            addButtonText: "Add Brewer".localized,
            addAnotherText: "Add Another Brewer".localized,
            onAdd: { showingBrewerForm = true }
        )
    }
    
    private func equipmentStepContent<T: Identifiable>(
        items: [T],
        icon: String,
        itemName: @escaping (T) -> String,
        addButtonText: String,
        addAnotherText: String,
        onAdd: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 16) {
            if items.isEmpty {
                Button {
                    onAdd()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                        Text(addButtonText)
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(items.prefix(3)), id: \.id) { item in
                        EquipmentItemRow(
                            item: item,
                            icon: icon,
                            itemName: itemName
                        )
                    }
                    
                    if items.count > 3 {
                        Text("+ %d more".localized(with: items.count - 3))
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    
                    Button {
                        onAdd()
                    } label: {
                        Text(addAnotherText)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.accent)
                    }
                    .padding(.top, 8)
                }
            }
        }
        .errorAlert()
    }
}

private struct EquipmentItemRow<T: Identifiable>: View {
    let item: T
    let icon: String
    let itemName: (T) -> String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.accent)
            Text(itemName(item))
                .foregroundStyle(AppTheme.textPrimary)
            Spacer()
        }
        .padding()
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

extension OnboardingView {
    private var completeStepContent: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                if !beans.isEmpty {
                            summaryRow(icon: "leaf.fill", text: localizedCountText(count: beans.count, singularKey: "Bean count singular", pluralKey: "Bean count plural"))
                }
                if !grinders.isEmpty {
                            summaryRow(icon: "gearshape.fill", text: localizedCountText(count: grinders.count, singularKey: "Grinder count singular", pluralKey: "Grinder count plural"))
                }
                if !machines.isEmpty {
                            summaryRow(icon: "cup.and.saucer.fill", text: localizedCountText(count: machines.count, singularKey: "Machine count singular", pluralKey: "Machine count plural"))
                }
                if !brewers.isEmpty {
                            summaryRow(icon: "drop.circle.fill", text: localizedCountText(count: brewers.count, singularKey: "Brewer count singular", pluralKey: "Brewer count plural"))
                }
            }
            .padding()
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
    
    private func summaryRow(icon: String, text: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 24)
            Text(text)
                .foregroundStyle(AppTheme.textPrimary)
            Spacer()
        }
    }
    
    private func localizedCountText(count: Int, singularKey: String, pluralKey: String) -> String {
        let labelKey = count == 1 ? singularKey : pluralKey
        return "\(count) \(labelKey.localized)"
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            switch currentStep {
            case .welcome:
                Button {
                    nextStep()
                } label: {
                    Text("Get Started".localized)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            case .bean:
                if beans.isEmpty {
                    VStack(spacing: 12) {
                        Button {
                            showingBeanForm = true
                        } label: {
                            Text("Add Bean".localized)
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        Button {
                            setupLater()
                        } label: {
                            Text("Set up later".localized)
                                .font(.headline)
                                .foregroundStyle(AppTheme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                } else {
                    Button {
                        nextStep()
                    } label: {
                        Text("Continue".localized)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
            case .grinder:
                if grinders.isEmpty {
                    HStack(spacing: 12) {
                        Button {
                            skipStep()
                        } label: {
                            Text("Skip".localized)
                                .font(.headline)
                                .foregroundStyle(AppTheme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        
                        Button {
                            showingGrinderForm = true
                        } label: {
                            Text("Add".localized)
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                } else {
                    HStack(spacing: 12) {
                        Button {
                            skipStep()
                        } label: {
                            Text("Skip".localized)
                                .font(.headline)
                                .foregroundStyle(AppTheme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        
                        Button {
                            nextStep()
                        } label: {
                            Text("Continue".localized)
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                }
            case .machine:
                if machines.isEmpty {
                    HStack(spacing: 12) {
                        Button {
                            skipStep()
                        } label: {
                            Text("Skip".localized)
                                .font(.headline)
                                .foregroundStyle(AppTheme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        
                        Button {
                            showingMachineForm = true
                        } label: {
                            Text("Add".localized)
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                } else {
                    HStack(spacing: 12) {
                        Button {
                            skipStep()
                        } label: {
                            Text("Skip".localized)
                                .font(.headline)
                                .foregroundStyle(AppTheme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        
                        Button {
                            nextStep()
                        } label: {
                            Text("Continue".localized)
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                }
            case .brewer:
                if brewers.isEmpty {
                    HStack(spacing: 12) {
                        Button {
                            skipStep()
                        } label: {
                            Text("Skip".localized)
                                .font(.headline)
                                .foregroundStyle(AppTheme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        
                        Button {
                            showingBrewerForm = true
                        } label: {
                            Text("Add".localized)
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                } else {
                    HStack(spacing: 12) {
                        Button {
                            skipStep()
                        } label: {
                            Text("Skip".localized)
                                .font(.headline)
                                .foregroundStyle(AppTheme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        
                        Button {
                            nextStep()
                        } label: {
                            Text("Continue".localized)
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                }
            case .complete:
                Button {
                    completeOnboarding()
                } label: {
                    Text("Start Brewing".localized)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
    }
    
    private func nextStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if let next = OnboardingStep(rawValue: currentStep.rawValue + 1) {
                currentStep = next
            }
        }
    }
    
    private func skipStep() {
        nextStep()
    }

    private func setupLater() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = .complete
        }
    }
    
    private func completeOnboarding() {
        hasCompletedOnboarding = true
    }
}


