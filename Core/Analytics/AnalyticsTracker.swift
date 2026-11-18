import OSLog

enum AnalyticsEvent: String, Sendable {
    case onboardingCompleted = "onboarding_completed"
    case screenTimePermissionApproved = "screen_time_permission_approved"
    case screenTimePermissionDenied = "screen_time_permission_denied"
    case screenTimePermissionRequestFailed = "screen_time_permission_request_failed"
    case homeViewed = "home_viewed"
    case friendsViewed = "friends_viewed"
    case duelsViewed = "duels_viewed"
    case settingsViewed = "settings_viewed"
    case dashboardLoadFailed = "dashboard_load_failed"
    case friendsStoreLoadFailed = "friends_store_load_failed"
    case duelsStoreLoadFailed = "duels_store_load_failed"
    case liveActivityStartFailed = "live_activity_start_failed"
    case friendRequestSent = "friend_request_sent"
    case friendRequestReceived = "friend_request_received"
    case friendRequestAccepted = "friend_request_accepted"
    case friendRequestDeclined = "friend_request_declined"
    case duelChallengeCreated = "duel_challenge_created"
    case duelAccepted = "duel_accepted"
    case duelDeclined = "duel_declined"
    case duelResolved = "duel_resolved"
    case resultCardGenerated = "result_card_generated"
    case liveActivityStarted = "live_activity_started"
    case liveActivityEnded = "live_activity_ended"
}

@MainActor
protocol AnalyticsTracking {
    func track(_ event: AnalyticsEvent)
}

@MainActor
struct LocalAnalyticsTracker: AnalyticsTracking {
    private let logger = Logger(subsystem: "mic.Pocket-Monk", category: "analytics")

    func track(_ event: AnalyticsEvent) {
        logger.info("event=\(event.rawValue, privacy: .public)")
    }
}
