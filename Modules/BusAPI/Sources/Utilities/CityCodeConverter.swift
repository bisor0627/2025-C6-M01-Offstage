import CoreLocation
import Foundation

/// Matches a reverse-geocoded place to a bus city. TAGO's own city list
/// (getCtyCodeList, cached by the relay) replaces the table the app used to ship.
public enum CityCodeConverter {
    /// City code the app uses for the Seoul API; TAGO doesn't serve Seoul.
    public static let seoul = "1000"

    public static func isSeoul(_ placemark: CLPlacemark) -> Bool {
        isSeoul(locality: placemark.locality, administrativeArea: placemark.administrativeArea)
    }

    public static func isSeoul(locality: String?, administrativeArea: String?) -> Bool {
        [locality, administrativeArea].contains("서울특별시")
    }

    public static func findCode(from placemark: CLPlacemark, in cities: [BusCity]) -> String? {
        findCode(locality: placemark.locality, administrativeArea: placemark.administrativeArea, in: cities)
    }

    /// Exact names first, so 경기 광주시 and 광주광역시 stay apart; then names
    /// without their administrative suffix, so 세종특별자치시 finds TAGO's 세종특별시.
    public static func findCode(locality: String?, administrativeArea: String?, in cities: [BusCity]) -> String? {
        if isSeoul(locality: locality, administrativeArea: administrativeArea) {
            return seoul
        }
        let names = [locality, administrativeArea].compactMap { $0 }
        for name in names {
            if let city = cities.first(where: { $0.name == name }) {
                return String(city.code)
            }
        }
        for name in names {
            let stem = stem(of: name)
            if let city = cities.first(where: { self.stem(of: $0.name) == stem }) {
                return String(city.code)
            }
        }
        return nil
    }

    private static let suffixes = ["특별자치시", "특별자치도", "특별시", "광역시", "시", "군", "도"]

    static func stem(of name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        for suffix in suffixes where trimmed.hasSuffix(suffix) && trimmed.count > suffix.count {
            return String(trimmed.dropLast(suffix.count))
        }
        return trimmed
    }
}
