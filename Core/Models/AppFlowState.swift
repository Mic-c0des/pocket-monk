import Foundation

enum AppFlowState: Equatable, Sendable {
    case loading
    case onboarding
    case accountAccess
    case permissionGate
    case blocked
    case ready
}
