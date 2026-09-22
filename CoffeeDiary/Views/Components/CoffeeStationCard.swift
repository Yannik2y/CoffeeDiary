import SwiftUI
import SwiftData

struct CoffeeStationCard: View {
    @Query(sort: \Machine.name) private var machines: [Machine]
    @Query(sort: \Grinder.name) private var grinders: [Grinder]

    var onLogEspresso: () -> Void
    var onLogFilter: () -> Void
    var embeddedInList: Bool = false

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

                VStack(spacing: 10) {
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
        }
    }

    @ViewBuilder
    private func stationItem(title: String, subtitle: String, symbol: String, photoData: Data?) -> some View {
        HStack(spacing: 12) {
            Group {
                if photoData != nil {
                    CachedThumbnailImage(data: photoData, maxDimension: 88)
                        .accessibilityHidden(true)
                } else {
                    Image(systemName: symbol)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .frame(width: 36, height: 36)
            .background(Color.accentColor.opacity(0.16))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}
