import BusAPI
import CoreLocation
import Foundation

@MainActor
final class BusRouteSearchViewModel: ObservableObject {
    @Published var busRoutes: [BusRouteWithArrival] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isFiltered = false
    @Published var recognizedText: String

    private let busRepository = MainBusRepository()
    let busStop: BusStop

    private var refreshTask: Task<Void, Never>?
    private(set) var allBusRoutes: [BusRouteWithArrival] = []

    var allBusRoutesLoaded: Bool {
        !allBusRoutes.isEmpty
    }

    init(busStop: BusStop, recognizedText: String) {
        self.busStop = busStop
        self.recognizedText = recognizedText
    }

    func performSearch() {
        filterBusRoutes()
    }

    deinit {
        refreshTask?.cancel()
    }

    func startAutoRefresh() {
        // 기존 작업이 있으면 취소
        refreshTask?.cancel()

        refreshTask = Task {
            // 초기 로드
            await fetchBusRoutes()

            // 30초마다 자동 새로고침
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: RefreshInterval.busArrival)
                } catch {
                    break
                }

                if Task.isCancelled {
                    break
                }

                await fetchBusRoutes()
            }
        }
    }

    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    func fetchBusRoutes() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let cityCodeString = try await BusCityRouting.code(for: busStop, locationProvider: LocationManager.shared)

            let routes = try await busRepository.fetchRoutesPassingThroughStop(
                cityCode: cityCodeString,
                nodeId: busStop.nodeId
            )

            let arrivals = try await busRepository.fetchStopArrivals(
                cityCode: cityCodeString,
                nodeId: busStop.nodeId
            )

            allBusRoutes = routes.map { route in
                let matchingArrival = arrivals.first { arrival in
                    arrival.routeId == route.routeId
                }
                return BusRouteWithArrival(route: route, arrival: matchingArrival)
            }
            filterBusRoutes()
        } catch {
            print("Error fetching bus routes: \(error)")
            errorMessage = error.busLoadMessage
            allBusRoutes = []
            busRoutes = []
        }
    }

    private func filterBusRoutes() {
        if recognizedText.isEmpty {
            busRoutes = allBusRoutes
            isFiltered = false
        } else {
            busRoutes = allBusRoutes.filter { routeWithArrival in
                routeWithArrival.route.routeNumber.contains(recognizedText)
            }
            isFiltered = true
        }
    }
}
