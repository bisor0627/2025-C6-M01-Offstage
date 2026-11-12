import BusAPI
import CoreLocation
import Foundation

/// Decides which bus API serves a place and which city code a stop belongs to.
enum BusCityRouting {
    static let seoul = CityCodeConverter.seoul

    /// Seoul stops come from the Seoul API. Elsewhere TAGO's GPS search needs no
    /// city code, so a failed reverse geocode no longer means "search Seongnam":
    /// it tries TAGO, then Seoul. TAGO alone can't decide Seoul, because it also
    /// returns other cities' stops there (Gangnam answers with Incheon stops).
    static func nearbyStops(
        around coordinate: CLLocationCoordinate2D,
        repository: BusRepository,
        locationProvider: LocationProviding
    ) async throws -> [BusStop] {
        let placemark = try? await locationProvider.fetchPlacemark(from: coordinate)
        if let placemark, CityCodeConverter.isSeoul(placemark) {
            return try await repository.fetchStopsNearby(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                cityCode: seoul
            )
        }
        let stops = try await repository.fetchStopsNearby(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            cityCode: nil
        )
        if stops.isEmpty, placemark == nil {
            return try await repository.fetchStopsNearby(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                cityCode: seoul
            )
        }
        return stops
    }

    /// City code for route and arrival lookups at this stop: the one the stop
    /// came with (TAGO's, or 1000 for Seoul), else its place matched against
    /// TAGO's city list.
    static func code(
        for stop: BusStop,
        repository: BusRepository,
        locationProvider: LocationProviding
    ) async throws -> String {
        if let cityCode = stop.cityCode {
            return String(cityCode)
        }
        let coordinate = CLLocationCoordinate2D(latitude: stop.latitude, longitude: stop.longitude)
        guard let placemark = try? await locationProvider.fetchPlacemark(from: coordinate) else {
            throw BusAPIError.missingParameter(name: "cityCode")
        }
        if CityCodeConverter.isSeoul(placemark) {
            return seoul
        }
        let cities = try await TagoCityList.shared.cities(from: repository)
        guard let code = CityCodeConverter.findCode(from: placemark, in: cities) else {
            throw BusAPIError.missingParameter(name: "cityCode")
        }
        return code
    }
}

/// TAGO's city list, fetched once per launch (the relay caches it for a week).
actor TagoCityList {
    static let shared = TagoCityList()
    private var cities: [BusCity]?

    func cities(from repository: BusRepository) async throws -> [BusCity] {
        if let cities {
            return cities
        }
        let fetched = try await repository.fetchCities(for: .stop)
        cities = fetched
        return fetched
    }
}
