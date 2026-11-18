import Combine
import Foundation

@MainActor
final class LiveActivityViewModel: ObservableObject {
    @Published private(set) var isAvailable: Bool
    @Published private(set) var isActive: Bool
    @Published private(set) var errorMessage: String?

    private let service: any MonkLiveActivityServicing
    private let analytics: any AnalyticsTracking

    init(
        service: any MonkLiveActivityServicing = MonkLiveActivityService(),
        analytics: any AnalyticsTracking = LocalAnalyticsTracker()
    ) {
        self.service = service
        self.analytics = analytics
        isAvailable = service.isAvailable
        isActive = service.isActive
    }

    var presentation: LiveActivityPresentation {
        LiveActivityPresentation.make(isAvailable: isAvailable, isActive: isActive)
    }

    func refreshIfActive(snapshot: DashboardSnapshot) async {
        await service.updateIfNeeded(snapshot: snapshot)
        refreshStatus()
    }

    func performAction(snapshot: DashboardSnapshot) async {
        errorMessage = nil

        if isActive {
            await service.end()
            analytics.track(.liveActivityEnded)
        } else {
            do {
                try service.start(snapshot: snapshot)
                analytics.track(.liveActivityStarted)
            } catch {
                analytics.track(.liveActivityStartFailed)
                errorMessage = error.localizedDescription
            }
        }

        refreshStatus()
    }

    private func refreshStatus() {
        isAvailable = service.isAvailable
        isActive = service.isActive
    }
}
