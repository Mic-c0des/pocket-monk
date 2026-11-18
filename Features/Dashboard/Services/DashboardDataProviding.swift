import Foundation

protocol DashboardDataProviding: Sendable {
    func loadDashboardData() async throws -> DashboardData?
}
