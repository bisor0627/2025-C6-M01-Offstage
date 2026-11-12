import BusAPI
import CoreLocation
import Foundation

/// Decides which bus API serves a place and which city code a stop belongs to.
enum BusCityRouting {
    static let seoul = "1000"

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
        let detected = placemark.flatMap { CityCodeConverter.findCode(from: $0) }
        if detected == seoul {
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
    /// came with (TAGO's, or 1000 for Seoul), else the reverse-geocoded one.
    static func code(for stop: BusStop, locationProvider: LocationProviding) async throws -> String {
        if let cityCode = stop.cityCode {
            return String(cityCode)
        }
        let coordinate = CLLocationCoordinate2D(latitude: stop.latitude, longitude: stop.longitude)
        if let placemark = try? await locationProvider.fetchPlacemark(from: coordinate),
           let code = CityCodeConverter.findCode(from: placemark)
        {
            return code
        }
        throw BusAPIError.missingParameter(name: "cityCode")
    }
}
