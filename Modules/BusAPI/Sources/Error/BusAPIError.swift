import Foundation
import Moya

/// Errors thrown by the Bus API module.
public enum BusAPIError: Error {
    /// Thrown when a required parameter is missing.
    case missingParameter(name: String)
    /// Thrown when the API responds with a non-success status header.
    case invalidStatus(header: BusAPIHeader)
    /// Thrown when the API responds without a body or items payload.
    case emptyBody
    /// Thrown when a successful API call returns no results.
    case noResults
    /// Thrown when decoding the response payload fails.
    case decodingFailed(Error)
    /// Thrown when the underlying Moya request fails.
    case network(MoyaError)
    /// Thrown when the relay refuses this device for a minute (HTTP 429).
    case rateLimited
    /// Thrown when the relay has used today's upstream quota (HTTP 503).
    case dailyLimitReached
    /// Thrown when the public bus API failed behind the relay (HTTP 502).
    case upstreamUnavailable
    /// Thrown for unknown or unhandled errors.
    case unknown(String)
}

extension BusAPIError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .missingParameter(name):
            "Missing required parameter: \(name)"
        case let .invalidStatus(header):
            "Bus API returned error code \(header.resultCode): \(header.resultMessage)"
        case .emptyBody:
            "Bus API returned an empty body."
        case .noResults:
            "The API request was successful, but returned no results."
        case let .decodingFailed(error):
            "Failed to decode Bus API response: \(error.localizedDescription)"
        case let .network(error):
            "Bus API network request failed: \(error.localizedDescription)"
        case .rateLimited:
            "Too many bus requests from this device. Try again in a minute."
        case .dailyLimitReached:
            "Today's bus lookup limit has been reached."
        case .upstreamUnavailable:
            "The public bus API is not answering."
        case let .unknown(message):
            "An unknown Bus API error occurred: \(message)"
        }
    }
}

public extension BusAPIError {
    /// Maps the relay's own refusals to errors; `nil` for any other status.
    init?(relayStatus: Int) {
        switch relayStatus {
        case 429: self = .rateLimited
        case 502: self = .upstreamUnavailable
        case 503: self = .dailyLimitReached
        default: return nil
        }
    }
}
