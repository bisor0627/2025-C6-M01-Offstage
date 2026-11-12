import BusAPI
import Foundation

struct BusRouteWithArrival: Identifiable, Equatable {
    let id: String
    let route: BusRoute
    let arrival: BusArrival?

    init(route: BusRoute, arrival: BusArrival?) {
        id = route.id
        self.route = route
        self.arrival = arrival
    }
}
