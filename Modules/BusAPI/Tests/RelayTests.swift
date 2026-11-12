@testable import BusAPI
import Foundation
import Moya
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
        #expect(URL(target: target).absoluteString
            ==
            "https://busonda-relay.foodfit-relay.workers.dev/v1/tago/ArvlInfoInqireService/getSttnAcctoArvlPrearngeInfoList")
        let parameters = queryParameters(target.task)
        #expect(parameters["serviceKey"] == nil)
        #expect(parameters["_type"] as? String == "json")
        #expect(parameters["nodeId"] as? String == "GGB206000681")
    }

    @Test
    func seoulTargetsGoThroughRelayWithoutKey() {
        let target = SeoulBusAPITarget.getStationArrivals(arsId: "02218")
        #expect(URL(target: target).absoluteString
            == "https://busonda-relay.foodfit-relay.workers.dev/v1/seoul/stationinfo/getStationByUid")
        #expect(queryParameters(target.task)["serviceKey"] == nil)
    }

    /// getBusRouteList ignores busRouteId and returns every Seoul route, so an id
    /// lookup must use getRouteInfo and a number search must send strSrch.
    @Test
    func seoulRouteLookupsUseTheRightOperation() {
        let byId = SeoulBusAPITarget.getRouteInfo(routeId: "100100063")
        #expect(byId.path == "/busRouteInfo/getRouteInfo")
        #expect(queryParameters(byId.task)["busRouteId"] as? String == "100100063")

        let byNumber = SeoulBusAPITarget.searchRoutes(routeNumber: "402")
        #expect(byNumber.path == "/busRouteInfo/getBusRouteList")
        #expect(queryParameters(byNumber.task)["strSrch"] as? String == "402")
        #expect(queryParameters(byNumber.task)["busRouteId"] == nil)
    }

    // MARK: - Repositories against a stubbed relay

    @Test
    func tagoDecodesRelayAnswer() async throws {
        let repository = TagoBusRepository(provider: stubbedProvider(status: 200, body: Self.arrivalsJSON))
        let arrivals = try await repository.fetchStopArrivals(cityCode: "31020", nodeId: "GGB206000681")
        #expect(arrivals.count == 2)
        #expect(arrivals.first?.routeNumber == "375")
        #expect(arrivals.first?.estimatedArrivalTime == 56)
    }

    @Test(arguments: [(429, "rateLimited"), (502, "upstreamUnavailable"), (503, "dailyLimitReached")])
    func tagoSurfacesRelayRefusal(status: Int, expected: String) async {
        let repository = TagoBusRepository(provider: stubbedProvider(status: status, body: #"{"error":"x"}"#))
        await #expect(throws: (any Error).self) {
            do {
                _ = try await repository.fetchStopArrivals(cityCode: "31020", nodeId: "N")
            } catch let error as BusAPIError {
                #expect(caseName(error) == expected)
                throw error
            }
        }
    }

    @Test
    func seoulSurfacesDailyLimit() async {
        let repository = SeoulBusRepository(provider: stubbedProvider(status: 503, body: #"{"error":"daily cap"}"#))
        await #expect(throws: (any Error).self) {
            do {
                _ = try await repository.fetchStopArrivals(cityCode: "1000", nodeId: "02218")
            } catch let error as BusAPIError {
                #expect(caseName(error) == "dailyLimitReached")
                throw error
            }
        }
    }

    // MARK: - Helpers

    static let arrivalsJSON = """
    {"response":{"header":{"resultCode":"00","resultMsg":"NORMAL SERVICE."},"body":{"items":{"item":[
    {"arrprevstationcnt":1,"arrtime":56,"nodeid":"GGB206000681","nodenm":"판교역서편","routeid":"GGB204000181","routeno":375},
    {"arrprevstationcnt":5,"arrtime":446,"nodeid":"GGB206000681","nodenm":"판교역서편","routeid":"GGB204000079","routeno":380}
    ]},"numOfRows":10,"pageNo":1,"totalCount":2}}}
    """
}

private func stubbedProvider<T: TargetType>(status: Int, body: String) -> MoyaProvider<T> {
    MoyaProvider<T>(
        endpointClosure: { target in
            Endpoint(
                url: URL(target: target).absoluteString,
                sampleResponseClosure: { .networkResponse(status, Data(body.utf8)) },
                method: target.method,
                task: target.task,
                httpHeaderFields: target.headers
            )
        },
        stubClosure: MoyaProvider.immediatelyStub
    )
}

private func queryParameters(_ task: Moya.Task) -> [String: Any] {
    if case let .requestParameters(parameters, _) = task {
        return parameters
    }
    return [:]
}

private func caseName(_ error: BusAPIError) -> String {
    switch error {
    case .rateLimited: "rateLimited"
    case .dailyLimitReached: "dailyLimitReached"
    case .upstreamUnavailable: "upstreamUnavailable"
    default: String(describing: error)
    }
}
