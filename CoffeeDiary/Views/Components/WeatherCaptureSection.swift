import SwiftUI

struct WeatherCaptureSection: View {
    @StateObject private var weatherViewModel = WeatherCaptureViewModel()
    @Binding var snapshot: WeatherSnapshot?

    var body: some View {
        Section("Weather".localized) {
            Text("Capture weather context".localized)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)

            weatherStatusView

            if let snapshot {
                weatherSummaryView(snapshot)
            }

            Button {
                weatherViewModel.refresh()
            } label: {
                Label("Fetch current weather".localized, systemImage: "location.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isWeatherButtonDisabled)
        }
        .onReceive(weatherViewModel.$snapshot) { snapshot = $0 }
    }

    @ViewBuilder
    private var weatherStatusView: some View {
        switch weatherViewModel.phase {
        case .idle:
            weatherStatusText("Tap \"Fetch current weather\" to save temperature and humidity for this brew.".localized, color: AppTheme.textSecondary)
        case .requestingPermission:
            weatherStatusText("Requesting location permission…".localized, color: AppTheme.textSecondary)
        case .locating:
            weatherStatusText("Locating you…".localized, color: AppTheme.textSecondary)
        case .fetching:
            weatherStatusText("Fetching weather data…".localized, color: AppTheme.textSecondary)
        case .success:
            weatherStatusText("Weather data saved".localized, color: AppTheme.accent)
        case .failure(let error):
            weatherStatusText(error.message, color: .red)
        }
    }

    private func weatherStatusText(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var isWeatherButtonDisabled: Bool {
        switch weatherViewModel.phase {
        case .requestingPermission, .locating, .fetching:
            return true
        default:
            return false
        }
    }

    @ViewBuilder
    private func weatherSummaryView(_ snapshot: WeatherSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Weather location".localized)
                Spacer()
                Text(snapshot.locationName)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            HStack {
                Text("Temperature".localized)
                Spacer()
                Text(String(format: "%.1f °C", snapshot.temperatureCelsius))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            HStack {
                Text("Humidity".localized)
                Spacer()
                Text(String(format: "%.0f %%", snapshot.humidityPercent))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .font(.subheadline)
    }
}
