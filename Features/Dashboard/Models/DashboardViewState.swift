import Foundation

enum DashboardViewState: Equatable, Sendable {
    case loading
    case empty
    case loaded(DashboardSnapshot)
    case failed(String)
}
