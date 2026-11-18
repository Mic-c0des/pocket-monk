import Combine
import Foundation

@MainActor
final class LiveActivityViewModel: ObservableObject {
    @Published private(set) var isAvailable: Bool
    @Published private(set) var isActive: Bool
    @Published private(set) var errorMessage: String?

    private let service: any MonkLiveActivityServicing

    init(service: any MonkLiveActivityServicing = MonkLiveActivityService()) {
        self.service = service
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
        } else {
            do {
                try service.start(snapshot: snapshot)
            } catch {
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
