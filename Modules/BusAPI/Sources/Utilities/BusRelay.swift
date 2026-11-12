import Foundation

/// The TAGO services the app calls; each one has its own city-code list.
public enum BusAPIService: CaseIterable, Sendable {
    case location
    case stop
    case route
    case arrival
}

/// The 버스온다 relay (`relay/` in this repo). It adds the data.go.kr key on the
/// server, so the app ships no API keys.
public enum BusRelay {
    public static let baseURL = URL(string: "https://busonda-relay.foodfit-relay.workers.dev")!
}
