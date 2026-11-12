import Foundation
import Logging

public final class SeoulBusRepository: BusRepository {
    private let transport: RelayTransport
    private let decoder: JSONDecoder
    private let logger = Logger(label: "BusAPI.SeoulBusRepository")

    public init(transport: RelayTransport = URLSessionTransport(), decoder: JSONDecoder = JSONDecoder()) {
        self.transport = transport
        self.decoder = decoder
    }

    /// Sends a request through the relay; relay refusals arrive as `BusAPIError`.
    private func request(_ target: SeoulBusAPITarget) async throws -> RelayResponse {
        logger.info("➡️ Request: \(target.path)")
        let response = try await transport.response(for: target)
        // Bodies only in debug builds: arrivals are polled every few seconds.
        #if DEBUG
            logger
                .info(
                    "⬅️ Response: \(target.path) status: \(response.statusCode)\n\(String(decoding: response.data, as: UTF8.self))"
                )
        #else
            logger.info("⬅️ Response: \(target.path) status: \(response.statusCode) (\(response.data.count) bytes)")
        #endif
        return response
    }

    public func fetchCities(for _: BusAPIService) async throws -> [BusCity] {
        // 서울시는 별도의 도시 목록 API를 사용하지 않음. 빈 배열 반환.
        []
    }

    // MARK: - BusRepository Conformance

    public func fetchRouteLocations(cityCode _: String, routeId: String, page _: Int?) async throws -> [BusLocation] {
        let response = try await request(.getBusPosByRtid(busRouteId: routeId))
        let body = try decoder.decode(SeoulBusLocationResponse.self, from: response.data)
        return body.msgBody.itemList.compactMap { dto in
            guard let lat = Double(dto.posY), let lon = Double(dto.posX) else { return nil }
            return BusLocation(
                routeId: routeId,
                routeNumber: dto.busRouteNm,
                vehicleNumber: dto.plainNo,
                nodeId: dto.arsId,
                nodeName: dto.stationNm,
                latitude: lat,
                longitude: lon
            )
        }
    }

    public func fetchRouteStations(cityCode _: String, routeId: String) async throws -> [BusRouteStation] {
        let response = try await request(.getStaionByRoute(busRouteId: routeId))
        let body = try decoder.decode(SeoulRouteStationResponse.self, from: response.data)

        return body.msgBody.itemList.compactMap { dto in
            guard let lat = Double(dto.gpsY),
                  let lon = Double(dto.gpsX)
            else {
                logger.warning("Failed to parse SeoulRouteStationDTO: \(dto)")
                return nil
            }
            return BusRouteStation(
                stationId: dto.arsId,
                stationName: dto.nodeNm,
                latitude: lat,
                longitude: lon
            )
        }
    }

    public func searchStops(cityCode _: String?, nodeName: String?, nodeNumber: String?) async throws -> [BusStop] {
        let searchTerm = nodeName ?? nodeNumber
        guard let searchTerm, !searchTerm.isEmpty else {
            return []
        }

        let response = try await request(.getStationByName(name: searchTerm))
        let body = try decoder.decode(SeoulKeywordStopResponse.self, from: response.data)
        return body.msgBody.itemList.compactMap { adaptToBusStop(from: $0) }
    }

    public func fetchStopsNearby(latitude: Double, longitude: Double, cityCode _: String?) async throws -> [BusStop] {
        let response = try await request(.getStationByPos(tmX: longitude, tmY: latitude))
        let body = try decoder.decode(SeoulGpsStopResponse.self, from: response.data)
        return body.msgBody.itemList.compactMap { adaptToBusStop(from: $0) }
    }

    public func fetchRoutesPassingThroughStop(cityCode _: String, nodeId: String) async throws -> [BusRoute] {
        let response = try await request(.getRouteByStation(arsId: nodeId))
        let body = try decoder.decode(SeoulStationRouteResponse.self, from: response.data)

        return body.msgBody.itemList.map { dto in
            BusRoute(
                routeId: dto.busRouteId,
                routeNumber: dto.busRouteNm
            )
        }
    }

    public func fetchRouteInfo(cityCode _: String, routeId: String) async throws -> BusRoute? {
        let response = try await request(.getRouteInfo(routeId: routeId))
        let body = try decoder.decode(SeoulRouteInfoResponse.self, from: response.data)
        return body.msgBody.itemList.first.map { dto in
            BusRoute(
                routeId: dto.busRouteId,
                routeNumber: dto.busRouteNm
            )
        }
    }

    public func searchRoutes(cityCode _: String, routeNumber: String) async throws -> [BusRoute] {
        let response = try await request(.searchRoutes(routeNumber: routeNumber))
        let body = try decoder.decode(SeoulRouteInfoResponse.self, from: response.data)
        return body.msgBody.itemList.map { dto in
            BusRoute(
                routeId: dto.busRouteId,
                routeNumber: dto.busRouteNm
            )
        }
    }

    public func fetchStopArrivals(cityCode _: String, nodeId: String) async throws -> [BusArrival] {
        let response = try await request(.getStationArrivals(arsId: nodeId))
        let body = try decoder.decode(SeoulArrivalResponse.self, from: response.data)

        return body.msgBody.itemList.flatMap { dto in
            adaptToBusArrival(from: dto)
        }
    }

    public func fetchRouteArrivals(cityCode: String, nodeId: String, routeId: String) async throws -> [BusArrival] {
        let all = try await fetchStopArrivals(cityCode: cityCode, nodeId: nodeId)
        return all.filter { $0.routeId == routeId }
    }

    // MARK: - Adapter helpers

    private func adaptToBusStop(from dto: SeoulGpsStopDTO) -> BusStop? {
        guard let lat = Double(dto.gpsY), let lon = Double(dto.gpsX) else { return nil }
        return BusStop(
            nodeId: dto.arsId,
            name: dto.stationNm,
            number: dto.arsId,
            cityCode: 1000,
            latitude: lat,
            longitude: lon
        )
    }

    private func adaptToBusStop(from dto: SeoulKeywordStopDTO) -> BusStop? {
        guard let lat = Double(dto.tmY), let lon = Double(dto.tmX) else { return nil }
        return BusStop(
            nodeId: dto.arsId,
            name: dto.stNm,
            number: dto.arsId,
            cityCode: 1000,
            latitude: lat,
            longitude: lon
        )
    }

    private func adaptToBusArrival(from dto: SeoulArrivalDTO) -> [BusArrival] {
        var results: [BusArrival] = []

        let candidates = [dto.arrmsg1, dto.arrmsg2]
        for msg in candidates {
            guard let parsed = SeoulArrivalParser.parse(msg) else { continue }

            let arrival = BusArrival(
                routeId: dto.busRouteId,
                routeNumber: dto.rtNm,
                nodeId: dto.arsId,
                nodeName: dto.stNm,
                remainingStopCount: parsed.remainingStops,
                estimatedArrivalTime: parsed.seconds
            )
            results.append(arrival)
        }

        return results
    }
}
