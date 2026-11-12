import SwiftUI

protocol Routable: Hashable {
    associatedtype V: View
    @MainActor @ViewBuilder func view() -> V
}
