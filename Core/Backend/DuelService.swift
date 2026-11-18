import Foundation
import SwiftData

@MainActor
protocol DuelServicing {
    func loadFriends() throws -> [FriendRecord]
    func loadDuels() throws -> [DuelRecord]
    func loadPointBalance() throws -> Int
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
    func resolveDuel(id: UUID, userZenScore: Int, now: Date) throws
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

    func loadPointBalance() throws -> Int {
        let account = try pointAccount(
            id: DuelPointRules.playerAccountID,
            now: .now
        )
        try modelContext.save()
        return account.balance
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
        let userAccount = try pointAccount(
            id: DuelPointRules.playerAccountID,
            now: now
        )
        let opponentAccount = try pointAccount(
            id: DuelPointRules.friendAccountID(for: normalizedUsername),
            now: now
        )
        guard userAccount.balance >= stakePoints,
              opponentAccount.balance >= stakePoints else {
            throw DuelServiceError.insufficientVirtualPoints
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
        guard DuelStake.pointOptions.contains(duel.stakePoints) else {
            throw DuelServiceError.invalidStake
        }
        let userAccount = try pointAccount(
            id: DuelPointRules.playerAccountID,
            now: now
        )
        let opponentAccount = try pointAccount(
            id: DuelPointRules.friendAccountID(for: duel.opponentUsername),
            now: now
        )
        guard userAccount.balance >= duel.stakePoints,
              opponentAccount.balance >= duel.stakePoints else {
            throw DuelServiceError.insufficientVirtualPoints
        }

        duel.status = .active
        duel.startedAt = now
        duel.endsAt = now.addingTimeInterval(TimeInterval(duel.durationSeconds))
        duel.updatedAt = now
        duel.userZenScoreAtStart = userZenScore
        duel.opponentZenScoreAtStart = DemoDuelScore.value(for: duel.opponentUsername)
        userAccount.balance -= duel.stakePoints
        opponentAccount.balance -= duel.stakePoints
        userAccount.updatedAt = now
        opponentAccount.updatedAt = now
        duel.stakesReserved = true
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

    func resolveDuel(id: UUID, userZenScore: Int, now: Date) throws {
        guard (0...100).contains(userZenScore) else {
            throw DuelServiceError.invalidZenScore
        }
        let duel = try duel(id: id)
        guard duel.status == .finished else {
            throw DuelServiceError.resultNotReady
        }
        guard duel.winner == nil, duel.resolvedAt == nil else {
            throw DuelServiceError.alreadyResolved
        }
        guard let userStartingScore = duel.userZenScoreAtStart,
              let opponentStartingScore = duel.opponentZenScoreAtStart else {
            throw DuelServiceError.missingStartScores
        }
        guard DuelStake.pointOptions.contains(duel.stakePoints) else {
            throw DuelServiceError.invalidStake
        }

        let userAccount = try pointAccount(
            id: DuelPointRules.playerAccountID,
            now: now
        )
        let opponentAccount = try pointAccount(
            id: DuelPointRules.friendAccountID(for: duel.opponentUsername),
            now: now
        )
        if !duel.stakesReserved {
            guard userAccount.balance >= duel.stakePoints,
                  opponentAccount.balance >= duel.stakePoints else {
                throw DuelServiceError.insufficientVirtualPoints
            }
            userAccount.balance -= duel.stakePoints
            opponentAccount.balance -= duel.stakePoints
        }

        let opponentEndingScore = DemoDuelResultScore.finalScore(
            startingScore: opponentStartingScore,
            opponentUsername: duel.opponentUsername,
            duelID: duel.id
        )
        let userChange = userZenScore - userStartingScore
        let opponentChange = opponentEndingScore - opponentStartingScore
        let winner = DuelRules.winner(
            userChange: userChange,
            opponentChange: opponentChange
        )

        switch winner {
        case .user:
            userAccount.balance += 2 * duel.stakePoints
        case .opponent:
            opponentAccount.balance += 2 * duel.stakePoints
        case .draw:
            userAccount.balance += duel.stakePoints
            opponentAccount.balance += duel.stakePoints
        }

        userAccount.updatedAt = now
        opponentAccount.updatedAt = now
        duel.userZenScoreAtEnd = userZenScore
        duel.opponentZenScoreAtEnd = opponentEndingScore
        duel.winner = winner
        duel.resolvedAt = now
        duel.stakesReserved = false
        duel.updatedAt = now
        try modelContext.save()
    }

    private func duel(id: UUID) throws -> DuelRecord {
        guard let duel = try loadDuels().first(where: { $0.id == id }) else {
            throw DuelServiceError.challengeNotFound
        }
        return duel
    }

    private func pointAccount(id: String, now: Date) throws -> DuelPointAccount {
        let accounts = try modelContext.fetch(FetchDescriptor<DuelPointAccount>())
        if let account = accounts.first(where: { $0.accountID == id }) {
            return account
        }

        let account = DuelPointAccount(accountID: id, updatedAt: now)
        modelContext.insert(account)
        return account
    }
}

nonisolated enum DemoDuelScore {
    static func value(for username: String) -> Int {
        let checksum = username.utf8.reduce(0) { ($0 * 31 + Int($1)) % 41 }
        return 55 + checksum
    }
}
