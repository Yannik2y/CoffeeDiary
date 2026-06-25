import SwiftUI
import SwiftData

struct CoffeeStationCard: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Machine.name) private var machines: [Machine]
    @Query(sort: \Grinder.name) private var grinders: [Grinder]

    var onLogEspresso: () -> Void
    var onLogFilter: () -> Void

    private var activeMachine: Machine? {
        machines.first(where: \.isActive) ?? machines.first
    }

    private var activeGrinder: Grinder? {
        grinders.first(where: \.isActive) ?? grinders.first
    }

    var body: some View {
        if activeMachine != nil || activeGrinder != nil {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Coffee Station".localized)
                        .font(.headline)
                    Spacer()
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(AppTheme.accentSecondary)
                }

                HStack(spacing: 12) {
                    if let machine = activeMachine {
                        stationItem(
                            title: machine.name,
                            subtitle: machine.brand ?? machine.model ?? "Machine".localized,
                            symbol: "cup.and.saucer.fill",
                            photoData: machine.displayPhotoData
                        )
                    }
                    if let grinder = activeGrinder {
                        stationItem(
                            title: grinder.name,
                            subtitle: grinder.brand ?? "Grinder".localized,
                            symbol: "gearshape.fill",
                            photoData: grinder.displayPhotoData
                        )
                    }
                }

                HStack(spacing: 10) {
                    Button(action: onLogEspresso) {
                        Label("Espresso".localized, systemImage: "cup.and.saucer.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.accent)

                    Button(action: onLogFilter) {
                        Label("Filter".localized, systemImage: "drop.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(16)
            .cardStyle(cornerRadius: 20)
            .padding(.horizontal, 20)
        }
    }

    @ViewBuilder
    private func stationItem(title: String, subtitle: String, symbol: String, photoData: Data?) -> some View {
        HStack(spacing: 10) {
            Group {
                if let photoData, let image = UIImage(data: photoData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: symbol)
                        .font(.title3)
                        .foregroundStyle(AppTheme.accent)
                }
            }
            .frame(width: 44, height: 44)
            .background(AppTheme.subtleBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }
}
