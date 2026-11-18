import Combine
import Foundation
import SwiftData

@MainActor
final class DuelViewModel: ObservableObject {
    @Published private(set) var friends: [FriendRecord] = []
    @Published private(set) var duels: [DuelRecord] = []
    @Published private(set) var errorMessage: String?
    @Published private(set) var confirmationMessage: String?
    @Published private(set) var hasLoaded = false

    private var service: (any DuelServicing)?

    init(service: (any DuelServicing)? = nil) {
        self.service = service
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
        guard let service else {
            errorMessage = DuelServiceError.serviceNotReady.localizedDescription
            hasLoaded = true
            return
        }

        do {
            try service.finishExpiredDuels(now: .now)
            try refreshData(using: service)
        } catch {
            errorMessage = error.localizedDescription
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
        perform { service in
            let duel = try service.createDuel(
                opponentUsername: opponentUsername,
                duration: duration,
                customEndDate: customEndDate,
                stakePoints: stakePoints,
                now: .now
            )
            return "Challenge sent to @\(duel.opponentUsername)."
        }
    }

    @discardableResult
    func acceptDuel(id: UUID, currentZenScore: Int?) -> Bool {
        perform { service in
            guard let currentZenScore else {
                throw DuelServiceError.missingZenScore
            }
            try service.acceptDuel(
                id: id,
                userZenScore: currentZenScore,
                now: .now
            )
            return "The demo duel is active."
        }
    }

    @discardableResult
    func declineDuel(id: UUID) -> Bool {
        perform { service in
            try service.declineDuel(id: id, now: .now)
            return "Challenge declined."
        }
    }

    func refresh() {
        load()
    }

    private func perform(
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
    }
}
