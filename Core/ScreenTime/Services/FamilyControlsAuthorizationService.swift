@preconcurrency import FamilyControls
import Foundation

@MainActor
final class FamilyControlsAuthorizationService: ScreenTimeAuthorizationServicing {
    private let authorizationCenter = AuthorizationCenter.shared

    func currentStatus() -> ScreenTimePermissionStatus {
        Self.permissionStatus(for: authorizationCenter.authorizationStatus)
    }

    func requestAuthorization() async throws -> ScreenTimePermissionStatus {
        do {
            try await authorizationCenter.requestAuthorization(for: .individual)
        } catch {
            let status = currentStatus()
            guard status == .denied else {
                throw error
            }
            return status
        }

        return currentStatus()
    }

    private static func permissionStatus(
        for authorizationStatus: AuthorizationStatus
    ) -> ScreenTimePermissionStatus {
        switch authorizationStatus {
        case .notDetermined:
            .notDetermined
        case .denied:
            .denied
        case .approved, .approvedWithDataAccess:
            .approved
        @unknown default:
            .notDetermined
        }
    }
}
