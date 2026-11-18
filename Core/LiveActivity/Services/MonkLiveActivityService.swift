import ActivityKit
import Combine
import Foundation

@MainActor
protocol MonkLiveActivityServicing {
    var isAvailable: Bool { get }
    var isActive: Bool { get }

    func start(snapshot: DashboardSnapshot) throws
    func updateIfNeeded(snapshot: DashboardSnapshot) async
    func end() async
}

@MainActor
final class MonkLiveActivityService: MonkLiveActivityServicing {
    private let authorizationInfo: ActivityAuthorizationInfo

    init(authorizationInfo: ActivityAuthorizationInfo = ActivityAuthorizationInfo()) {
        self.authorizationInfo = authorizationInfo
    }

    var isAvailable: Bool {
        authorizationInfo.areActivitiesEnabled
    }

    var isActive: Bool {
        !Activity<MonkActivityAttributes>.activities.isEmpty
    }

    func start(snapshot: DashboardSnapshot) throws {
        guard isAvailable else {
            throw MonkLiveActivityError.unavailable
        }
        guard !isActive else {
            throw MonkLiveActivityError.alreadyActive
        }

        let now = Date.now
        let attributes = MonkActivityAttributes(monkName: snapshot.monk.name)
        let content = ActivityContent(
            state: contentState(for: snapshot, updatedAt: now),
            staleDate: now.addingTimeInterval(60 * 60)
        )
        _ = try Activity.request(attributes: attributes, content: content)
    }

    func updateIfNeeded(snapshot: DashboardSnapshot) async {
        guard let activity = Activity<MonkActivityAttributes>.activities.first,
              LiveActivityUpdateCadence.shouldUpdate(
                  lastUpdatedAt: activity.content.state.updatedAt,
                  now: .now
              )
        else {
            return
        }

        let now = Date.now
        await activity.update(
            ActivityContent(
                state: contentState(for: snapshot, updatedAt: now),
                staleDate: now.addingTimeInterval(60 * 60)
            )
        )
    }

    func end() async {
        for activity in Activity<MonkActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    private func contentState(
        for snapshot: DashboardSnapshot,
        updatedAt: Date
    ) -> MonkActivityAttributes.ContentState {
        MonkActivityAttributes.ContentState(
            mood: snapshot.mood.title,
            zenScore: snapshot.zenScore,
            updatedAt: updatedAt
        )
    }
}

enum MonkLiveActivityError: LocalizedError {
    case unavailable
    case alreadyActive

    var errorDescription: String? {
        switch self {
        case .unavailable:
            String(localized: "Live Activities are turned off for Pocket Monk.")
        case .alreadyActive:
            String(localized: "A monk Live Activity is already active.")
        }
    }
}
