import SwiftUI
import SwiftData

struct BrewDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var entry: BrewEntry
    @State private var showingEdit = false
    @State private var confirmDelete = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(entry.coffeeName)
                                .font(.system(.title2, design: .rounded, weight: .bold))
                                .foregroundStyle(AppTheme.textPrimary)

                            Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.system(.subheadline, design: .rounded, weight: .regular))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        Spacer()
                        Button {
                            entry.isFavorite.toggle()
                            ErrorHandler.save(modelContext, errorMessage: "Failed to update favorite status. Please try again.".localized)
                        } label: {
                            Image(systemName: entry.isFavorite ? "star.fill" : "star")
                                .foregroundStyle(entry.isFavorite ? .yellow : AppTheme.textSecondary)
                        }
                        .accessibilityLabel(entry.isFavorite ? "Unfavorite".localized : "Favorite".localized)
                    }

                    HStack(spacing: 8) {
                        DetailBadge(text: entry.brewStyle.title, systemImage: entry.brewStyle == .espresso ? "cup.and.saucer.fill" : "drop.fill", color: AppTheme.accent)
                        if entry.brewStyle == .espresso {
                            DetailBadge(text: entry.shotType.displayName, systemImage: "cup.and.saucer", color: AppTheme.accentSecondary)
                        }
                        DetailBadge(text: Formatters.ratioString(dose: entry.doseGrams, yield: entry.yieldGrams), systemImage: "arrow.left.arrow.right", color: AppTheme.accentSecondary)
                        DetailBadge(text: String(format: "%.1f", entry.grinderSetting), systemImage: "dial.medium.fill", color: AppTheme.accent)
                    }
                    
                    if entry.rating > 0 {
                        HStack(spacing: 8) {
                            Text("Rating".localized)
                                .font(.system(.subheadline, design: .rounded, weight: .medium))
                                .foregroundStyle(AppTheme.textSecondary)
                            StarRatingDisplayView(rating: entry.rating, size: 20)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle(cornerRadius: 20)
                
                // Brew Metrics Card
                VStack(alignment: .leading, spacing: 18) {
                    MetricRow(
                        icon: "scalemass.fill",
                        label: "Dose".localized,
                        value: String(format: "%.1f g", entry.doseGrams),
                        color: AppTheme.accent
                    )
                    
                    Divider()
                        .background(AppTheme.textSecondary.opacity(0.2))
                    
                    MetricRow(
                        icon: "scalemass.fill",
                        label: "Yield".localized,
                        value: String(format: "%.1f g", entry.yieldGrams),
                        color: AppTheme.accentSecondary
                    )
                    
                    Divider()
                        .background(AppTheme.textSecondary.opacity(0.2))
                    
                    MetricRow(
                        icon: "timer",
                        label: "Time".localized,
                        value: Formatters.secondsString(entry.brewTimeSeconds),
                        color: AppTheme.accent
                    )
                    
                    if entry.preInfusionTimeSeconds > 0 {
                        Divider()
                            .background(AppTheme.textSecondary.opacity(0.2))
                        MetricRow(
                            icon: "clock.arrow.circlepath",
                            label: "Pre-infusion time".localized,
                            value: "\(entry.preInfusionTimeSeconds) " + "s".localized,
                            color: AppTheme.accentSecondary
                        )
                    }
                    
                    if entry.brewPressureBar > 0 {
                        Divider()
                            .background(AppTheme.textSecondary.opacity(0.2))
                        MetricRow(
                            icon: "gauge",
                            label: "Brew pressure".localized,
                            value: String(format: "%.1f bar", entry.brewPressureBar),
                            color: AppTheme.accent
                        )
                    }
                    
                    if entry.grinderTimerSeconds > 0 {
                        Divider()
                            .background(AppTheme.textSecondary.opacity(0.2))
                        
                        MetricRow(
                            icon: "timelapse",
                            label: "Grinder timer".localized,
                            value: "\(Formatters.number.string(from: NSNumber(value: entry.grinderTimerSeconds)) ?? String(format: "%.1f", entry.grinderTimerSeconds)) s",
                            color: AppTheme.accentSecondary
                        )
                    }
                
                if entry.bloomWaterGrams > 0 || entry.bloomTimeSeconds > 0 {
                    Divider()
                        .background(AppTheme.textSecondary.opacity(0.2))
                    
                    MetricRow(
                        icon: "drop.circle",
                        label: "Bloom".localized,
                        value: "\(Int(entry.bloomWaterGrams)) g / \(entry.bloomTimeSeconds) s",
                        color: AppTheme.accentSecondary
                    )
                }
                
                if entry.totalWaterInputGrams > 0 {
                    Divider()
                        .background(AppTheme.textSecondary.opacity(0.2))
                    
                    MetricRow(
                        icon: "drop.triangle.fill",
                        label: "Total water".localized,
                        value: "\(Int(entry.totalWaterInputGrams)) g",
                        color: AppTheme.accent
                    )
                }
                
                if entry.waterTemperatureCelsius > 0 {
                    Divider()
                        .background(AppTheme.textSecondary.opacity(0.2))
                    
                    MetricRow(
                        icon: "thermometer",
                        label: "Water temperature".localized,
                        value: "\(Int(entry.waterTemperatureCelsius)) °C",
                        color: AppTheme.accentSecondary
                    )
                }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle(cornerRadius: 20)
                
                if entry.weatherTemperatureCelsius != nil ||
                    entry.weatherHumidityPercent != nil ||
                    entry.weatherLocationName != nil {
                    VStack(alignment: .leading, spacing: 18) {
                        Label("Weather".localized, systemImage: "cloud.sun.fill")
                            .font(.system(.headline, design: .rounded, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                        
                        if let location = entry.weatherLocationName {
                            MetricRow(
                                icon: "mappin.and.ellipse",
                                label: "Weather location".localized,
                                value: location,
                                color: AppTheme.accentSecondary
                            )
                        }
                        
                        if let temperature = entry.weatherTemperatureCelsius {
                            Divider()
                                .background(AppTheme.textSecondary.opacity(0.2))
                            MetricRow(
                                icon: "thermometer.sun.fill",
                                label: "Temperature".localized,
                                value: String(format: "%.1f °C", temperature),
                                color: AppTheme.accent
                            )
                        }
                        
                        if let humidity = entry.weatherHumidityPercent {
                            Divider()
                                .background(AppTheme.textSecondary.opacity(0.2))
                            MetricRow(
                                icon: "drop.degreesign",
                                label: "Humidity".localized,
                                value: String(format: "%.0f %%", humidity),
                                color: AppTheme.accentSecondary
                            )
                        }
                        
                        if let captureDate = entry.weatherCaptureDate {
                            Divider()
                                .background(AppTheme.textSecondary.opacity(0.2))
                            Text("Weather last updated %@".localized(with: captureDate.formatted(date: .abbreviated, time: .shortened)))
                                .font(.system(.footnote, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle(cornerRadius: 20)
                }
                
                // Equipment Card
                if entry.bean != nil || entry.grinder != nil || entry.machine != nil || entry.brewer != nil {
                    VStack(alignment: .leading, spacing: 16) {
                        if let bean = entry.bean {
                            EquipmentRow(icon: "leaf.fill", label: "Bean".localized, value: bean.name)
                            if entry.grinder != nil || entry.machine != nil || entry.brewer != nil {
                                Divider()
                                    .background(AppTheme.textSecondary.opacity(0.2))
                            }
                        }
                        if let grinder = entry.grinder {
                            EquipmentRow(icon: "gearshape.fill", label: "Grinder".localized, value: grinder.name)
                            if entry.machine != nil || entry.brewer != nil {
                                Divider()
                                    .background(AppTheme.textSecondary.opacity(0.2))
                            }
                        }
                        if let machine = entry.machine {
                            EquipmentRow(icon: "wrench.and.screwdriver.fill", label: "Machine".localized, value: machine.name)
                            if entry.brewer != nil {
                                Divider()
                                    .background(AppTheme.textSecondary.opacity(0.2))
                            }
                        }
                        if let brewer = entry.brewer {
                            EquipmentRow(icon: "drop.fill", label: "Brewer".localized, value: brewer.name)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle(cornerRadius: 20)
                }
                
                // Notes Card
                if let notes = entry.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Notes".localized, systemImage: "note.text")
                            .font(.system(.headline, design: .rounded, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(notes)
                            .font(.system(.body, design: .rounded, weight: .regular))
                            .foregroundStyle(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle(cornerRadius: 20)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(AppTheme.subtleBackground)
        }
        .navigationTitle("Brew".localized)
        .tint(AppTheme.accent)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Edit".localized) { showingEdit = true }
                    Button("Duplicate".localized, systemImage: "doc.on.doc") {
                        duplicate()
                    }
                    Button("Delete".localized, systemImage: "trash", role: .destructive) {
                        confirmDelete = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .confirmationDialog("Delete this brew?".localized, isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete".localized, role: .destructive) {
                modelContext.delete(entry)
                ErrorHandler.save(modelContext, errorMessage: "Failed to delete brew entry. Please try again.".localized) {
                dismiss()
                }
            }
            Button("Cancel".localized, role: .cancel) {}
        } message: {
            Text("This action cannot be undone.".localized)
        }
        .sheet(isPresented: $showingEdit) {
            BrewFormView(editingEntry: entry)
        }
        .errorAlert()
    }
    
    private struct DetailBadge: View {
        let text: String
        let systemImage: String
        let color: Color
        
        init(text: String, systemImage: String, color: Color = AppTheme.accent) {
            self.text = text
            self.systemImage = systemImage
            self.color = color
        }
        
        var body: some View {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(.caption2, weight: .semibold))
                    .foregroundStyle(color)
                Text(text)
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(Color.primary)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                Capsule()
                    .fill(Color(.secondarySystemFill))
            )
        }
    }
    
    private struct MetricRow: View {
        let icon: String
        let label: String
        let value: String
        let color: Color
        
        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(.body, weight: .medium))
                    .foregroundStyle(color)
                    .frame(width: 24, alignment: .leading)
                
                Text(label)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)
                
                Spacer()
                
                Text(value)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
            }
        }
    }
    
    private struct EquipmentRow: View {
        let icon: String
        let label: String
        let value: String
        
        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(.body, weight: .medium))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 24, alignment: .leading)
                
                Text(label)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)
                
                Spacer()
                
                Text(value)
                    .font(.system(.body, design: .rounded, weight: .regular))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }
    
    private func duplicate() {
        _ = BrewStore.shared.duplicate(entry, in: modelContext)
        BrewStore.shared.save(modelContext, errorMessage: "Failed to duplicate brew entry. Please try again.".localized)
    }
}


