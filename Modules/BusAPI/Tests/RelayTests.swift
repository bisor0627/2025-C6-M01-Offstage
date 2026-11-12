@testable import BusAPI
import Foundation
import Testing

/// Requests go to the relay without keys, and the relay's refusals surface as BusAPIError.
struct RelayTests {
    // MARK: - Relay status mapping

    @Test(arguments: [(429, "rateLimited"), (502, "upstreamUnavailable"), (503, "dailyLimitReached")])
    func relayRefusalsMapToErrors(status: Int, expected: String) {
        #expect(BusAPIError(relayStatus: status).map(caseName) == expected)
    }

    @Test(arguments: [200, 400, 404, 500])
    func otherStatusesAreNotRelayRefusals(status: Int) {
        #expect(BusAPIError(relayStatus: status) == nil)
    }

    // MARK: - Request shape

    @Test
    func tagoTargetsGoThroughRelayWithoutKey() {
        let target = BusAPITarget(.stopArrivals(cityCode: "31020", nodeId: "GGB206000681"))
        let expected = "https://busonda-relay.foodfit-relay.workers.dev/v1/tago/ArvlInfoInqireService/"
            + "getSttnAcctoArvlPrearngeInfoList?_type=json&cityCode=31020&nodeId=GGB206000681"
        #expect(target.url.absoluteString == expected)
        #expect(query(target)["serviceKey"] == nil)
    }

    @Test
    func seoulTargetsGoThroughRelayWithoutKey() {
        let target = SeoulBusAPITarget.getStationArrivals(arsId: "02218")
        let expected = "https://busonda-relay.foodfit-relay.workers.dev/v1/seoul/stationinfo/"
            + "getStationByUid?arsId=02218&resultType=json"
        #expect(target.url.absoluteString == expected)
        #expect(query(target)["serviceKey"] == nil)
    }

    /// getBusRouteList ignores busRouteId and returns every Seoul route, so an id
    /// lookup must use getRouteInfo and a number search must send strSrch.
    @Test
    func seoulRouteLookupsUseTheRightOperation() {
        let byId = SeoulBusAPITarget.getRouteInfo(routeId: "100100063")
        #expect(byId.path == "/busRouteInfo/getRouteInfo")
        #expect(query(byId)["busRouteId"] == "100100063")

        let byNumber = SeoulBusAPITarget.searchRoutes(routeNumber: "402")
        #expect(byNumber.path == "/busRouteInfo/getBusRouteList")
        #expect(query(byNumber)["strSrch"] == "402")
        #expect(query(byNumber)["busRouteId"] == nil)
    }

    @Test
    func nilParametersAreLeftOut() {
        let target = BusAPITarget(.stopSearch(cityCode: "31020", nodeName: "판교", nodeNumber: nil))
        #expect(query(target)["nodeNm"] == "판교")
        #expect(!target.queryItems.contains { $0.name == "nodeNo" })
    }

    // MARK: - Repositories against a stubbed relay

    @Test
    func tagoDecodesRelayAnswer() async throws {
        let repository = TagoBusRepository(transport: StubTransport(status: 200, body: Self.arrivalsJSON))
        let arrivals = try await repository.fetchStopArrivals(cityCode: "31020", nodeId: "GGB206000681")
        #expect(arrivals.count == 2)
        #expect(arrivals.first?.routeNumber == "375")
        #expect(arrivals.first?.estimatedArrivalTime == 56)
    }

    @Test(arguments: [(429, "rateLimited"), (502, "upstreamUnavailable"), (503, "dailyLimitReached")])
    func tagoSurfacesRelayRefusal(status: Int, expected: String) async {
        let repository = TagoBusRepository(transport: StubTransport(status: status, body: #"{"error":"x"}"#))
        let error = await busError { _ = try await repository.fetchStopArrivals(cityCode: "31020", nodeId: "N") }
        #expect(error.map(caseName) == expected)
    }

    @Test
    func seoulSurfacesDailyLimit() async {
        let repository = SeoulBusRepository(transport: StubTransport(status: 503, body: #"{"error":"daily cap"}"#))
        let error = await busError { _ = try await repository.fetchStopArrivals(cityCode: "1000", nodeId: "02218") }
        #expect(error.map(caseName) == "dailyLimitReached")
    }

    @Test
    func transportFailureBecomesNetworkError() async {
        let repository = TagoBusRepository(transport: StubTransport(error: URLError(.notConnectedToInternet)))
        let error = await busError { _ = try await repository.fetchStopArrivals(cityCode: "31020", nodeId: "N") }
        guard case let .network(underlying)? = error else {
            Issue.record("expected .network, got \(String(describing: error))")
            return
        }
        #expect((underlying as? URLError)?.code == .notConnectedToInternet)
    }

    // MARK: - Fixtures

    static let arrivalsJSON = """
    {"response":{"header":{"resultCode":"00","resultMsg":"NORMAL SERVICE."},"body":{"items":{"item":[
    {"arrprevstationcnt":1,"arrtime":56,"nodeid":"GGB206000681","nodenm":"판교역서편","routeid":"GGB204000181","routeno":375},
    {"arrprevstationcnt":5,"arrtime":446,"nodeid":"GGB206000681","nodenm":"판교역서편","routeid":"GGB204000079","routeno":380}
    ]},"numOfRows":10,"pageNo":1,"totalCount":2}}}
    """
}

/// Answers every request with a fixed status and body, or a transport error.
private struct StubTransport: RelayTransport {
    var status = 200
    var body = ""
    var error: (any Error & Sendable)?

    init(status: Int, body: String) {
        self.status = status
        self.body = body
    }

    init(error: any Error & Sendable) {
        self.error = error
    }

    func send(_: URL) async throws -> RelayResponse {
        if let error {
            throw error
        }
        return RelayResponse(statusCode: status, data: Data(body.utf8))
    }
}

/// The BusAPIError thrown by `body`, or nil when it succeeds or throws something else.
private func busError(_ body: () async throws -> Void) async -> BusAPIError? {
    do {
        try await body()
        return nil
    } catch {
        return error as? BusAPIError
    }
}

private func query(_ request: some RelayRequest) -> [String: String] {
    Dictionary(request.queryItems.map { ($0.name, $0.value ?? "") }, uniquingKeysWith: { first, _ in first })
}

private func caseName(_ error: BusAPIError) -> String {
    switch error {
    case .rateLimited: "rateLimited"
    case .dailyLimitReached: "dailyLimitReached"
    case .upstreamUnavailable: "upstreamUnavailable"
    default: String(describing: error)
    }
}
