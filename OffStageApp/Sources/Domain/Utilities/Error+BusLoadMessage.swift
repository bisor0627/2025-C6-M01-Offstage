import BusAPI
import Foundation

extension Error {
    /// What to tell the user (and VoiceOver) when bus data failed to load.
    var busLoadMessage: String {
        if case .dailyLimitReached? = self as? BusAPIError {
            return String(localized: "home.map.dailyLimit")
        }
        return String(localized: "home.map.loadFailed")
    }
}
