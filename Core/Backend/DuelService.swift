import Foundation
import SwiftData

@MainActor
protocol DuelServicing {
    func loadFriends() throws -> [FriendRecord]
    func loadDuels() throws -> [DuelRecord]
    func createDuel(
        opponentUsername: String,
        duration: DuelDurationOption,
        customEndDate: Date,
        stakePoints: Int,
        now: Date
    ) throws -> DuelRecord
    func acceptDuel(id: UUID, userZenScore: Int, now: Date) throws
    func declineDuel(id: UUID, now: Date) throws
    func finishExpiredDuels(now: Date) throws
}

@MainActor
final class LocalDuelService: DuelServicing {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadFriends() throws -> [FriendRecord] {
        try LocalFriendService(modelContext: modelContext)
            .loadFriends()
            .filter { $0.status == .friends }
    }

    func loadDuels() throws -> [DuelRecord] {
        try modelContext.fetch(
            FetchDescriptor<DuelRecord>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
        )
    }

    func createDuel(
        opponentUsername: String,
        duration: DuelDurationOption,
        customEndDate: Date,
        stakePoints: Int,
        now: Date
    ) throws -> DuelRecord {
        let normalizedUsername = opponentUsername.lowercased()
        guard try loadFriends().contains(where: {
            $0.username == normalizedUsername
        }) else {
            throw DuelServiceError.opponentIsNotAFriend
        }
        guard DuelStake.pointOptions.contains(stakePoints) else {
            throw DuelServiceError.invalidStake
        }

        let duels = try loadDuels()
        guard !duels.contains(where: {
            $0.opponentUsername == normalizedUsername
                && ($0.status == .pending || $0.status == .active)
        }) else {
            throw DuelServiceError.duplicateChallenge
        }

        let duel = DuelRecord(
            opponentUsername: normalizedUsername,
            duration: duration,
            durationSeconds: try DuelRules.durationSeconds(
                for: duration,
                customEndDate: customEndDate,
                now: now
            ),
            stakePoints: stakePoints,
            createdAt: now
        )
        modelContext.insert(duel)
        try modelContext.save()
        return duel
    }

    func acceptDuel(id: UUID, userZenScore: Int, now: Date) throws {
        guard (0...100).contains(userZenScore) else {
            throw DuelServiceError.invalidZenScore
        }
        let duel = try duel(id: id)
        guard duel.status == .pending else {
            throw DuelServiceError.invalidChallengeState
        }
        guard duel.durationSeconds > 0 else {
            throw DuelServiceError.invalidDuration
        }

        duel.status = .active
        duel.startedAt = now
        duel.endsAt = now.addingTimeInterval(TimeInterval(duel.durationSeconds))
        duel.updatedAt = now
        duel.userZenScoreAtStart = userZenScore
        duel.opponentZenScoreAtStart = DemoDuelScore.value(for: duel.opponentUsername)
        try modelContext.save()
    }

    func declineDuel(id: UUID, now: Date) throws {
        let duel = try duel(id: id)
        guard duel.status == .pending else {
            throw DuelServiceError.invalidChallengeState
        }
        duel.status = .declined
        duel.updatedAt = now
        try modelContext.save()
    }

    func finishExpiredDuels(now: Date) throws {
        let activeDuels = try loadDuels().filter { $0.status == .active }
        for duel in activeDuels {
            guard let endsAt = duel.endsAt else {
                throw DuelServiceError.invalidChallengeState
            }
            if endsAt <= now {
                duel.status = .finished
                duel.updatedAt = now
            }
        }
        try modelContext.save()
    }

    private func duel(id: UUID) throws -> DuelRecord {
        guard let duel = try loadDuels().first(where: { $0.id == id }) else {
            throw DuelServiceError.challengeNotFound
        }
        return duel
    }
}

nonisolated enum DemoDuelScore {
    static func value(for username: String) -> Int {
        let checksum = username.utf8.reduce(0) { ($0 * 31 + Int($1)) % 41 }
        return 55 + checksum
    }
}
