import Combine
import Foundation
import SwiftData

@MainActor
final class DuelViewModel: ObservableObject {
    @Published private(set) var friends: [FriendRecord] = []
    @Published private(set) var duels: [DuelRecord] = []
    @Published private(set) var errorMessage: String?
    @Published private(set) var loadErrorMessage: String?
    @Published private(set) var confirmationMessage: String?
    @Published private(set) var pointBalance: Int?
    @Published private(set) var hasLoaded = false

    private var service: (any DuelServicing)?
    private let analytics: any AnalyticsTracking

    init(
        service: (any DuelServicing)? = nil,
        analytics: any AnalyticsTracking = LocalAnalyticsTracker()
    ) {
        self.service = service
        self.analytics = analytics
    }

    var pendingDuels: [DuelRecord] {
        duels.filter { $0.status == .pending }
    }

    var activeDuels: [DuelRecord] {
        duels.filter { $0.status == .active }
    }

    var finishedDuels: [DuelRecord] {
        duels.filter { $0.status == .finished }
    }

    var declinedDuels: [DuelRecord] {
        duels.filter { $0.status == .declined }
    }

    func load(using modelContext: ModelContext) {
        if service == nil {
            service = LocalDuelService(modelContext: modelContext)
        }
        load()
    }

    func load() {
        errorMessage = nil
        loadErrorMessage = nil
        guard let service else {
            let message = DuelServiceError.serviceNotReady.localizedDescription
            errorMessage = message
            loadErrorMessage = message
            hasLoaded = true
            return
        }

        do {
            try service.finishExpiredDuels(now: .now)
            try refreshData(using: service)
        } catch {
            errorMessage = error.localizedDescription
            loadErrorMessage = error.localizedDescription
            analytics.track(.duelsStoreLoadFailed)
        }
        hasLoaded = true
    }

    @discardableResult
    func createDuel(
        opponentUsername: String,
        duration: DuelDurationOption,
        customEndDate: Date,
        stakePoints: Int
    ) -> Bool {
        perform(event: .duelChallengeCreated) { service in
            let duel = try service.createDuel(
                opponentUsername: opponentUsername,
                duration: duration,
                customEndDate: customEndDate,
                stakePoints: stakePoints,
                now: .now
            )
            return String(localized: "Challenge sent to @\(duel.opponentUsername).")
        }
    }

    @discardableResult
    func acceptDuel(id: UUID, currentZenScore: Int?) -> Bool {
        perform(event: .duelAccepted) { service in
            guard let currentZenScore else {
                throw DuelServiceError.missingZenScore
            }
            try service.acceptDuel(
                id: id,
                userZenScore: currentZenScore,
                now: .now
            )
            return String(localized: "The demo duel is active.")
        }
    }

    @discardableResult
    func declineDuel(id: UUID) -> Bool {
        perform(event: .duelDeclined) { service in
            try service.declineDuel(id: id, now: .now)
            return String(localized: "Challenge declined.")
        }
    }

    @discardableResult
    func resolveDuel(id: UUID, currentZenScore: Int?) -> Bool {
        perform(event: .duelResolved) { service in
            guard let currentZenScore else {
                throw DuelServiceError.missingZenScore
            }
            try service.resolveDuel(
                id: id,
                userZenScore: currentZenScore,
                now: .now
            )
            return String(localized: "Your duel result is ready.")
        }
    }

    func refresh() {
        load()
    }

    private func perform(
        event: AnalyticsEvent,
        _ action: (any DuelServicing) throws -> String
    ) -> Bool {
        errorMessage = nil
        confirmationMessage = nil
        guard let service else {
            errorMessage = DuelServiceError.serviceNotReady.localizedDescription
            return false
        }

        do {
            confirmationMessage = try action(service)
            analytics.track(event)
            try refreshData(using: service)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func refreshData(using service: any DuelServicing) throws {
        friends = try service.loadFriends()
        duels = try service.loadDuels()
        pointBalance = try service.loadPointBalance()
    }
}
