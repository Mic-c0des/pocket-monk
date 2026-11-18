import Foundation

@MainActor
protocol ScreenTimeAuthorizationServicing {
    func currentStatus() -> ScreenTimePermissionStatus
    func requestAuthorization() async throws -> ScreenTimePermissionStatus
}
