import Foundation
import Combine
import CoreLocation

struct WeatherSnapshot: Equatable {
    let locationName: String
    let temperatureCelsius: Double
    let humidityPercent: Double
    let timestamp: Date
}

@MainActor
final class WeatherCaptureViewModel: NSObject, ObservableObject {
    enum Phase: Equatable {
        case idle
        case requestingPermission
        case locating
        case fetching
        case success(WeatherSnapshot)
        case failure(WeatherCaptureError)
    }
    
    @Published private(set) var phase: Phase = .idle
    @Published private(set) var snapshot: WeatherSnapshot?
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var awaitingAuthorization = false
    private static var cachedSnapshot: WeatherSnapshot?
    private static var cacheTimestamp: Date?
    private static let cacheLifetime: TimeInterval = 15 * 60

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    
    func refresh() {
        if let cached = Self.cachedSnapshot,
           let timestamp = Self.cacheTimestamp,
           Date().timeIntervalSince(timestamp) < Self.cacheLifetime {
            snapshot = cached
            phase = .success(cached)
            return
        }

        switch locationManager.authorizationStatus {
        case .notDetermined:
            awaitingAuthorization = true
            phase = .requestingPermission
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            requestLocation()
        case .denied, .restricted:
            phase = .failure(.permissionDenied)
        @unknown default:
            phase = .failure(.unknown)
        }
    }
    
    private func requestLocation() {
        phase = .locating
        locationManager.requestLocation()
    }
    
    private func fetchWeather(for location: CLLocation) async {
        phase = .fetching
        do {
            let snapshot = try await loadSnapshot(for: location)
            self.snapshot = snapshot
            Self.cachedSnapshot = snapshot
            Self.cacheTimestamp = Date()
            phase = .success(snapshot)
        } catch let error as WeatherCaptureError {
            phase = .failure(error)
        } catch {
            phase = .failure(.unknown)
        }
    }
    
    private func loadSnapshot(for location: CLLocation) async throws -> WeatherSnapshot {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(location.coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(location.coordinate.longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,relative_humidity_2m"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "1")
        ]
        
        guard let url = components?.url else {
            throw WeatherCaptureError.networkFailure
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw WeatherCaptureError.networkFailure
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(OpenMeteoResponse.self, from: data)
        guard let current = result.current else {
            throw WeatherCaptureError.noPayload
        }
        
        geocoder.cancelGeocode()
        let placemark = try? await geocoder.reverseGeocodeLocation(location).first
        let locationName = placemark?.locality ??
            placemark?.name ??
            "Current location".localized
        
        return WeatherSnapshot(
            locationName: locationName,
            temperatureCelsius: current.temperature2M,
            humidityPercent: current.relativeHumidity2M,
            timestamp: Date()
        )
    }
}

extension WeatherCaptureViewModel: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard awaitingAuthorization else { return }
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                awaitingAuthorization = false
                requestLocation()
            case .denied, .restricted:
                awaitingAuthorization = false
                phase = .failure(.permissionDenied)
            case .notDetermined:
                break
            @unknown default:
                awaitingAuthorization = false
                phase = .failure(.unknown)
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor [weak self] in
            self?.phase = .failure(.locationUnavailable)
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            Task { @MainActor [weak self] in
                self?.phase = .failure(.locationUnavailable)
            }
            return
        }
        Task { @MainActor [weak self] in
            await self?.fetchWeather(for: location)
        }
    }
}

private struct OpenMeteoResponse: Decodable {
    struct Current: Decodable {
        let temperature2M: Double
        let relativeHumidity2M: Double
        
        enum CodingKeys: String, CodingKey {
            case temperature2M = "temperature_2m"
            case relativeHumidity2M = "relative_humidity_2m"
        }
    }
    
    let current: Current?
}

enum WeatherCaptureError: Error, Equatable {
    case permissionDenied
    case locationUnavailable
    case networkFailure
    case noPayload
    case unknown
    
    var message: String {
        switch self {
        case .permissionDenied:
            return "Location permission required. Enable it in Settings to capture weather.".localized
        case .locationUnavailable:
            return "Unable to determine your location. Please try again.".localized
        case .networkFailure:
            return "Weather service unavailable. Try again in a moment.".localized
        case .noPayload:
            return "Weather data not available for this location.".localized
        case .unknown:
            return "Weather unavailable".localized
        }
    }
}

extension WeatherCaptureError: LocalizedError {
    var errorDescription: String? { message }
}

