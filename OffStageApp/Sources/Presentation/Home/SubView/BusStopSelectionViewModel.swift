import BusAPI
import Combine
import CoreLocation
import Foundation
import Observation

@MainActor
@Observable
final class BusStopSelectionViewModel {
    // MARK: - Data Model

    /// 정류장과 거리 정보를 함께 담는 구조체
    struct StopWithDistance: Identifiable {
        let stop: BusStop
        let distance: Double // 미터 단위

        var id: String {
            stop.nodeId
        }
    }

    // MARK: - Published Properties

    /// 근처 정류장 리스트 (거리 정보 포함)
    var nearbyStops: [StopWithDistance] = []

    /// 로딩 상태
    var isLoading = false

    /// 에러 메시지
    var errorMessage: String?

    // MARK: - Private Properties

    private var locationProvider: LocationProviding
    private let busRepository = MainBusRepository()

    // MARK: - Initializer

    init(locationProvider: LocationProviding = LocationManager.shared) {
        self.locationProvider = locationProvider
    }

    // MARK: - Private Methods

    /// 두 좌표 간의 거리를 계산 (미터 단위)
    private func calculateDistance(
        from userLocation: CLLocationCoordinate2D,
        to stopLocation: CLLocationCoordinate2D
    ) -> Double {
        let userCLLocation = CLLocation(
            latitude: userLocation.latitude,
            longitude: userLocation.longitude
        )
        let stopCLLocation = CLLocation(
            latitude: stopLocation.latitude,
            longitude: stopLocation.longitude
        )

        // CLLocation의 distance 메서드로 거리 계산 (미터 단위 반환)
        return userCLLocation.distance(from: stopCLLocation)
    }

    // MARK: - Public Methods

    func fetchNearbyStops() {
        Task {
            isLoading = true
            errorMessage = nil
            defer { isLoading = false }

            do {
                // 1. 현재 위치 가져오기
                let location = try await locationProvider.requestLocation()
                let coordinate = CLLocationCoordinate2D(
                    latitude: location.latitude,
                    longitude: location.longitude
                )

                // 2. 근처 정류장 가져오기 (서울이면 서울 API, 그 외 TAGO)
                let stops = try await BusCityRouting.nearbyStops(
                    around: coordinate,
                    repository: busRepository,
                    locationProvider: locationProvider
                )

                // 3. 각 정류장에 대해 거리 계산
                nearbyStops = stops.map { stop in
                    let distance = calculateDistance(
                        from: coordinate,
                        to: CLLocationCoordinate2D(
                            latitude: stop.latitude,
                            longitude: stop.longitude
                        )
                    )
                    return StopWithDistance(stop: stop, distance: distance)
                }
                .sorted { $0.distance < $1.distance } // 거리순으로 정렬

            } catch {
                print("Error fetching nearby stops: \(error)")
                errorMessage = error.busLoadMessage
                nearbyStops = []
            }
        }
    }
}
