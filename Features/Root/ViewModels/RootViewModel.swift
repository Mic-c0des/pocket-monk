import Combine
import Foundation

@MainActor
final class RootViewModel: ObservableObject {
    @Published private(set) var flowState: AppFlowState
    @Published private(set) var permissionStatus: ScreenTimePermissionStatus
    @Published private(set) var isRequestingPermission = false
    @Published private(set) var permissionErrorMessage: String?

    private let authorizationService: any ScreenTimeAuthorizationServicing
    private let persistOnboardingCompletion: @MainActor (Bool) -> Void
    private var hasCompletedOnboarding: Bool
    private let usesInjectedInitialState: Bool

    init(
        initialState: AppFlowState? = nil,
        authorizationService: (any ScreenTimeAuthorizationServicing)? = nil,
        hasCompletedOnboarding: Bool? = nil,
        persistOnboardingCompletion: @escaping @MainActor (Bool) -> Void = {
            UserDefaults.standard.set($0, forKey: "hasCompletedPocketMonkOnboarding")
        }
    ) {
        let service = authorizationService ?? FamilyControlsAuthorizationService()
        self.authorizationService = service
        self.persistOnboardingCompletion = persistOnboardingCompletion
        self.hasCompletedOnboarding = hasCompletedOnboarding
            ?? UserDefaults.standard.bool(forKey: "hasCompletedPocketMonkOnboarding")
        self.usesInjectedInitialState = initialState != nil
        self.flowState = initialState ?? .loading
        self.permissionStatus = service.currentStatus()
    }

    func load() {
        guard !usesInjectedInitialState else { return }
        refreshPermissionState()

        if !hasCompletedOnboarding {
            flowState = .onboarding
        }
    }

    func continueToAccountAccess() {
        flowState = .accountAccess
    }

    func continueAsGuest() {
        permissionStatus = authorizationService.currentStatus()
        switch permissionStatus {
        case .notDetermined:
            flowState = .permissionGate
        case .denied, .approved:
            routeAfterPermissionCheck()
        }
    }

    func requestScreenTimePermission() async {
        guard !isRequestingPermission else { return }

        isRequestingPermission = true
        permissionErrorMessage = nil
        defer { isRequestingPermission = false }

        do {
            permissionStatus = try await authorizationService.requestAuthorization()
            routeAfterPermissionCheck()
        } catch {
            permissionStatus = authorizationService.currentStatus()
            permissionErrorMessage = error.localizedDescription
            routeAfterPermissionCheck()
        }
    }

    func refreshPermissionState() {
        permissionStatus = authorizationService.currentStatus()
        guard hasCompletedOnboarding else { return }
        routeAfterPermissionCheck()
    }

    func continueWithApprovedPermission() {
        permissionStatus = authorizationService.currentStatus()
        routeAfterPermissionCheck()
    }

    private func routeAfterPermissionCheck() {
        switch permissionStatus {
        case .notDetermined:
            flowState = .permissionGate
        case .denied:
            completeOnboarding()
            flowState = .blocked
        case .approved:
            completeOnboarding()
            flowState = .ready
        }
    }

    private func completeOnboarding() {
        guard !hasCompletedOnboarding else { return }
        hasCompletedOnboarding = true
        persistOnboardingCompletion(true)
    }
}
