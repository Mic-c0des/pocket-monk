import Foundation

enum DuelInitiator: String, Codable, Sendable {
    /// The current user sent the challenge.
    case me
    /// The rival challenged the current user.
    case rival
}

enum DuelStatus: String, Codable, Sendable {
    case pending
    case active
    case finished
}

/// A challenge between the current user and one friend, seen from the current user's side.
/// It starts when the challenged person accepts and finishes on its own when the window closes.
struct Duel: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let rival: FriendProfile
    let initiator: DuelInitiator
    let duration: DuelDuration
    let stake: DuelStake
    let createdAt: Date
    private(set) var startedAt: Date?

    init(
        id: UUID = UUID(),
        rival: FriendProfile,
        initiator: DuelInitiator,
        duration: DuelDuration,
        stake: DuelStake,
        createdAt: Date,
        startedAt: Date? = nil
    ) {
        self.id = id
        self.rival = rival
        self.initiator = initiator
        self.duration = duration
        self.stake = stake
        self.createdAt = createdAt
        self.startedAt = startedAt
    }

    var isIncoming: Bool {
        initiator == .rival
    }

    var isPending: Bool {
        startedAt == nil
    }

    var endsAt: Date? {
        startedAt.map { duration.endDate(from: $0) }
    }

    func status(at date: Date) -> DuelStatus {
        guard let endsAt else {
            return .pending
        }
        return date < endsAt ? .active : .finished
    }

    /// Nil until the duel starts; zero once it has finished.
    func timeRemaining(at date: Date) -> TimeInterval? {
        endsAt.map { max($0.timeIntervalSince(date), 0) }
    }

    /// The share of the window that has passed, from 0 to 1.
    func elapsedFraction(at date: Date) -> Double {
        guard let startedAt else {
            return 0
        }
        let fraction = date.timeIntervalSince(startedAt) / duration.interval
        return min(max(fraction, 0), 1)
    }

    func starting(at date: Date) -> Duel {
        var duel = self
        duel.startedAt = date
        return duel
    }
}

/// What the current user asks for when sending a challenge.
struct DuelRequest: Equatable, Sendable {
    let rival: FriendProfile
    let duration: DuelDuration
    let stake: DuelStake
}
