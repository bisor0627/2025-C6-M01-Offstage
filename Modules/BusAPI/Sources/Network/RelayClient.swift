import Foundation

/// A GET request to the relay: where it goes and its query.
public protocol RelayRequest: Sendable {
    var baseURL: URL { get }
    var path: String { get }
    var queryItems: [URLQueryItem] { get }
}

public extension RelayRequest {
    var url: URL {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        components.queryItems = queryItems.isEmpty ? nil : queryItems.sorted { $0.name < $1.name }
        return components.url!
    }
}

/// Builds query items from optional values; nil values are left out.
func makeQueryItems(_ parameters: [String: (any Sendable)?]) -> [URLQueryItem] {
    parameters.compactMap { name, value in
        value.map { URLQueryItem(name: name, value: "\($0)") }
    }
}

public struct RelayResponse: Sendable {
    public let statusCode: Int
    public let data: Data

    public init(statusCode: Int, data: Data) {
        self.statusCode = statusCode
        self.data = data
    }
}

/// Sends relay requests. Repositories take one so tests can answer without a network.
public protocol RelayTransport: Sendable {
    func send(_ url: URL) async throws -> RelayResponse
}

public struct URLSessionTransport: RelayTransport {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func send(_ url: URL) async throws -> RelayResponse {
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        return RelayResponse(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, data: data)
    }
}

extension RelayTransport {
    /// Sends the request, wraps transport failures and turns relay refusals
    /// (429/502/503) into `BusAPIError`.
    func response(for request: some RelayRequest) async throws -> RelayResponse {
        let response: RelayResponse
        do {
            response = try await send(request.url)
        } catch {
            throw BusAPIError.network(error)
        }
        if let relayError = BusAPIError(relayStatus: response.statusCode) {
            throw relayError
        }
        return response
    }
}
