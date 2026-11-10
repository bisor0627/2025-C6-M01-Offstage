import Combine
import CoreLocation
import Foundation

import BusAPI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var nearestBusStop: BusStop?
    @Published var busRoutes: [BusRoute] = []
    @Published var isLoading = false
    /// Set when bus data could not be loaded, as opposed to "no stops nearby".
    @Published var loadFailure: LoadFailure?

    enum LoadFailure {
        /// The relay used today's public API quota.
        case dailyLimit
        /// Network, relay or public API failure; worth retrying.
        case unavailable
    }

    private var locationProvider: LocationProviding
    private let busRepository = MainBusRepository()

    init(locationProvider: LocationProviding = LocationManager.shared) {
        self.locationProvider = locationProvider
    }

    private func detectCityCode(from gps: CLLocationCoordinate2D) async throws -> String {
        guard let placemark = try await locationProvider.fetchPlacemark(from: gps) else {
            throw BusAPIError.unknown("Failed to fetch placemark for city code detection.")
        }
        let detectedCityCode = CityCodeConverter.findCode(from: placemark) ?? "31020" // Default to Seongnam
        return detectedCityCode
    }

    func fetchNearestStop() {
        Task {
            isLoading = true
            loadFailure = nil
            defer { isLoading = false }
            do {
                // 먼저 백그라운드에서 저장된 위치를 확인
                var coordinate: CLLocationCoordinate2D

                if let cachedLocation = BackgroundLocationManager.getLastKnownLocation() {
                    print("✅ Using cached location from background tracking")
                    coordinate = cachedLocation
                } else {
                    print("📍 Requesting fresh location")
                    let location = try await locationProvider.requestLocation()
                    coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                }

                let cityCodeString = try await detectCityCode(from: coordinate)
                let stops = try await busRepository.fetchStopsNearby(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    cityCode: cityCodeString
                )

                if let firstStop = stops.first {
                    nearestBusStop = firstStop
                    await fetchBusRoutes(for: firstStop)
                } else {
                    nearestBusStop = nil
                    busRoutes = []
                }

            } catch {
                print("Error fetching nearest stop: \(error)")
                loadFailure = Self.loadFailure(for: error)
                nearestBusStop = nil
                busRoutes = []
            }
        }
    }

    private func fetchBusRoutes(for stop: BusStop) async {
        do {
            let cityCodeString = try await detectCityCode(from: CLLocationCoordinate2D(
                latitude: stop.latitude,
                longitude: stop.longitude
            ))
            let routes = try await busRepository.fetchRoutesPassingThroughStop(
                cityCode: cityCodeString,
                nodeId: stop.nodeId
            )
            busRoutes = routes
        } catch {
            print("Error fetching bus routes: \(error)")
            loadFailure = Self.loadFailure(for: error)
            busRoutes = []
        }
    }

    /// Bus API errors become a visible failure; location errors keep the
    /// existing "no stops found" state.
    private static func loadFailure(for error: Error) -> LoadFailure? {
        guard let busError = error as? BusAPIError else { return nil }
        switch busError {
        case .dailyLimitReached:
            return .dailyLimit
        case .noResults:
            return nil
        default:
            return .unavailable
        }
    }
}
