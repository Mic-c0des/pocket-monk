import Foundation

/// The current user's duels, with the rules for creating them and moving between states.
/// Pending duels wait on the challenged person; active and finished follow the clock.
struct DuelBook: Equatable, Sendable {
    private(set) var duels: [Duel]

    init(duels: [Duel] = []) {
        // One record per duel; when records collide, the later one in the list wins.
        var byID: [UUID: Duel] = [:]
        for duel in duels {
            byID[duel.id] = duel
        }
        self.duels = Self.newestFirst(Array(byID.values))
    }

    var isEmpty: Bool {
        duels.isEmpty
    }

    var incomingChallenges: [Duel] {
        duels.filter { $0.isPending && $0.isIncoming }
    }

    var outgoingChallenges: [Duel] {
        duels.filter { $0.isPending && !$0.isIncoming }
    }

    func duel(with id: UUID) -> Duel? {
        duels.first { $0.id == id }
    }

    /// Soonest to finish first.
    func activeDuels(at date: Date) -> [Duel] {
        duels
            .filter { $0.status(at: date) == .active }
            .sorted { ($0.endsAt ?? .distantFuture) < ($1.endsAt ?? .distantFuture) }
    }

    /// Most recently finished first.
    func finishedDuels(at date: Date) -> [Duel] {
        duels
            .filter { $0.status(at: date) == .finished }
            .sorted { ($0.endsAt ?? .distantPast) > ($1.endsAt ?? .distantPast) }
    }

    /// A pending or active duel with this rival, if there is one.
    func openDuel(with rivalID: UUID, at date: Date) -> Duel? {
        duels.first { $0.rival.id == rivalID && $0.status(at: date) != .finished }
    }

    /// Friends who can't be challenged right now because a duel with them is already open.
    func busyRivalIDs(at date: Date) -> Set<UUID> {
        Set(duels.filter { $0.status(at: date) != .finished }.map(\.rival.id))
    }

    @discardableResult
    mutating func create(
        _ request: DuelRequest,
        by currentUser: FriendProfile,
        friends: [FriendProfile],
        at date: Date,
        id: UUID = UUID()
    ) throws -> Duel {
        let rival = request.rival
        guard rival.id != currentUser.id else {
            throw DuelError.cannotDuelSelf
        }
        guard friends.contains(where: { $0.id == rival.id }) else {
            throw DuelError.notFriends(rival.displayName)
        }
        guard request.duration.isValid else {
            throw DuelError.invalidDuration
        }
        if case let .custom(text) = request.stake {
            _ = try DuelStake.makeCustom(text)
        }
        // One open duel per friend keeps both screens measuring the same thing.
        guard openDuel(with: rival.id, at: date) == nil else {
            throw DuelError.alreadyDueling(rival.displayName)
        }

        let duel = Duel(
            id: id,
            rival: rival,
            initiator: .me,
            duration: request.duration,
            stake: request.stake,
            createdAt: date
        )
        duels = Self.newestFirst(duels + [duel])
        return duel
    }

    /// Starts the timer on a challenge someone sent the current user.
    @discardableResult
    mutating func accept(_ id: UUID, at date: Date) throws -> Duel {
        guard let index = duels.firstIndex(where: { $0.id == id }),
              duels[index].isPending,
              duels[index].isIncoming
        else {
            throw DuelError.duelNotFound
        }
        let started = duels[index].starting(at: date)
        duels[index] = started
        return started
    }

    mutating func decline(_ id: UUID) throws {
        guard let challenge = duel(with: id), challenge.isPending, challenge.isIncoming else {
            throw DuelError.duelNotFound
        }
        duels.removeAll { $0.id == id }
    }

    mutating func cancel(_ id: UUID) throws {
        guard let challenge = duel(with: id), challenge.isPending, !challenge.isIncoming else {
            throw DuelError.duelNotFound
        }
        duels.removeAll { $0.id == id }
    }

    private static func newestFirst(_ duels: [Duel]) -> [Duel] {
        duels.sorted {
            if $0.createdAt != $1.createdAt {
                return $0.createdAt > $1.createdAt
            }
            return $0.id.uuidString < $1.id.uuidString
        }
    }
}

enum DuelError: LocalizedError, Equatable, Sendable {
    case noRival
    case cannotDuelSelf
    case notFriends(String)
    case alreadyDueling(String)
    case invalidDuration
    case emptyStake
    case stakeTooLong
    case duelNotFound
    case notStarted

    var errorDescription: String? {
        switch self {
        case .noRival:
            "Choose a friend to challenge."
        case .cannotDuelSelf:
            "You can’t challenge yourself."
        case let .notFriends(name):
            "\(name) isn’t in your circle yet. Add them as a friend first."
        case let .alreadyDueling(name):
            "You already have an open duel with \(name)."
        case .invalidDuration:
            "Custom duels last \(DuelDuration.customDayRange.lowerBound) to \(DuelDuration.customDayRange.upperBound) days."
        case .emptyStake:
            "Describe the stake, or pick one of the suggestions."
        case .stakeTooLong:
            "Keep the stake to \(DuelStake.maximumCustomLength) characters or fewer."
        case .duelNotFound:
            "That duel is no longer available."
        case .notStarted:
            "This duel hasn’t started yet."
        }
    }
}
