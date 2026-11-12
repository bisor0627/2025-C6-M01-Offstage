import BusAPI
import Combine
import CoreLocation
import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var nearestBusStop: BusStop?
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

                let stops = try await BusCityRouting.nearbyStops(
                    around: coordinate,
                    repository: busRepository,
                    locationProvider: locationProvider
                )
                nearestBusStop = stops.first

            } catch {
                print("Error fetching nearest stop: \(error)")
                loadFailure = Self.loadFailure(for: error)
                nearestBusStop = nil
            }
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
