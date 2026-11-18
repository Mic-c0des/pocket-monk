import Foundation
import SwiftData

nonisolated enum DuelStatus: String, Codable, Hashable, Sendable {
    case pending
    case active
    case finished
    case declined

    var title: String {
        switch self {
        case .pending: String(localized: "Waiting for response")
        case .active: String(localized: "In progress")
        case .finished: String(localized: "Time complete")
        case .declined: String(localized: "Declined")
        }
    }

    var systemImage: String {
        switch self {
        case .pending: "clock"
        case .active: "figure.martial.arts"
        case .finished: "checkmark.circle"
        case .declined: "xmark.circle"
        }
    }
}

nonisolated enum DuelWinner: String, Codable, Hashable, Sendable {
    case user
    case opponent
    case draw

    var title: String {
        switch self {
        case .user: String(localized: "You win")
        case .opponent: String(localized: "Your friend wins")
        case .draw: String(localized: "It’s a draw")
        }
    }

    var systemImage: String {
        switch self {
        case .user: "trophy.fill"
        case .opponent: "figure.martial.arts"
        case .draw: "equal.circle.fill"
        }
    }
}

nonisolated enum DuelDurationOption: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case oneDay
    case oneWeek
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .oneDay: String(localized: "1 day")
        case .oneWeek: String(localized: "1 week")
        case .custom: String(localized: "Custom window")
        }
    }

    var fixedDurationSeconds: Int? {
        switch self {
        case .oneDay: DuelRules.secondsPerDay
        case .oneWeek: 7 * DuelRules.secondsPerDay
        case .custom: nil
        }
    }
}

nonisolated enum DuelStake {
    static let pointOptions = [0, 10, 25, 50]

    static func title(for points: Int) -> String? {
        guard pointOptions.contains(points) else { return nil }
        return points == 0
            ? String(localized: "No stake")
            : String(localized: "\(points) virtual points")
    }
}

nonisolated enum DuelPointRules {
    static let startingBalance = 100
    static let playerAccountID = "local-player"

    static func friendAccountID(for username: String) -> String {
        "friend:\(username.lowercased())"
    }
}

nonisolated enum DuelRules {
    static let secondsPerMinute = 60
    static let secondsPerHour = 60 * secondsPerMinute
    static let secondsPerDay = 24 * secondsPerHour

    static func durationSeconds(
        for option: DuelDurationOption,
        customEndDate: Date,
        now: Date
    ) throws -> Int {
        if let fixedDuration = option.fixedDurationSeconds {
            return fixedDuration
        }

        let duration = customEndDate.timeIntervalSince(now)
        guard duration > 0, duration.isFinite, duration < Double(Int.max) else {
            throw DuelServiceError.invalidDuration
        }
        return max(1, Int(duration.rounded(.up)))
    }

    static func countdown(endsAt: Date, now: Date) -> String {
        let totalSeconds = max(0, Int(endsAt.timeIntervalSince(now)))
        let days = totalSeconds / secondsPerDay
        let hours = (totalSeconds % secondsPerDay) / secondsPerHour
        let minutes = (totalSeconds % secondsPerHour) / secondsPerMinute
        let seconds = totalSeconds % secondsPerMinute
        let clock = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        return days > 0 ? "\(days)d \(clock)" : clock
    }

    static func durationLabel(
        for option: DuelDurationOption,
        seconds: Int
    ) -> String {
        guard option == .custom else { return option.title }

        let days = seconds / secondsPerDay
        if days > 0 {
            return String(localized: "Custom · \(days) \(days == 1 ? "day" : "days")")
        }

        let hours = seconds / secondsPerHour
        if hours > 0 {
            return String(localized: "Custom · \(hours) \(hours == 1 ? "hour" : "hours")")
        }

        let minutes = max(1, seconds / secondsPerMinute)
        return String(localized: "Custom · \(minutes) \(minutes == 1 ? "minute" : "minutes")")
    }

    static func winner(userChange: Int, opponentChange: Int) -> DuelWinner {
        if userChange > opponentChange {
            return .user
        }
        if opponentChange > userChange {
            return .opponent
        }
        return .draw
    }
}

nonisolated enum DemoDuelResultScore {
    static let maximumChange = 10
    private static let outcomeCount = maximumChange * 2 + 1

    static func finalScore(
        startingScore: Int,
        opponentUsername: String,
        duelID: UUID
    ) -> Int {
        let seed = "\(opponentUsername.lowercased())\(duelID.uuidString)"
        let checksum = seed.utf8.reduce(0) {
            ($0 * 31 + Int($1)) % outcomeCount
        }
        let change = checksum - maximumChange
        return min(max(startingScore + change, 0), 100)
    }
}

nonisolated enum DuelServiceError: LocalizedError, Equatable, Sendable {
    case opponentIsNotAFriend
    case duplicateChallenge
    case invalidDuration
    case invalidStake
    case challengeNotFound
    case invalidChallengeState
    case missingZenScore
    case invalidZenScore
    case serviceNotReady
    case insufficientVirtualPoints
    case resultNotReady
    case alreadyResolved
    case missingStartScores

    var errorDescription: String? {
        switch self {
        case .opponentIsNotAFriend:
            String(localized: "Choose someone from your accepted friends list.")
        case .duplicateChallenge:
            String(localized: "You already have a pending or active duel with this friend.")
        case .invalidDuration:
            String(localized: "Choose an end time after the duel starts.")
        case .invalidStake:
            String(localized: "Choose one of the available virtual point stakes.")
        case .challengeNotFound:
            String(localized: "This challenge is no longer available.")
        case .invalidChallengeState:
            String(localized: "This challenge can’t make that state change.")
        case .missingZenScore:
            String(localized: "Your zen score is unavailable. Try again after your dashboard loads.")
        case .invalidZenScore:
            String(localized: "The zen score must be between 0 and 100.")
        case .serviceNotReady:
            String(localized: "The local duel store isn’t ready yet. Try again.")
        case .insufficientVirtualPoints:
            String(localized: "One of the players doesn’t have enough virtual points for this stake.")
        case .resultNotReady:
            String(localized: "This duel must finish before its result can be resolved.")
        case .alreadyResolved:
            String(localized: "This duel’s result has already been resolved.")
        case .missingStartScores:
            String(localized: "The duel’s starting scores are unavailable, so its result can’t be resolved.")
        }
    }
}

@Model
final class DuelRecord {
    @Attribute(.unique) var id: UUID
    var opponentUsername: String
    var duration: DuelDurationOption
    var durationSeconds: Int
    var stakePoints: Int
    var status: DuelStatus
    var createdAt: Date
    var startedAt: Date?
    var endsAt: Date?
    var updatedAt: Date
    var userZenScoreAtStart: Int?
    var opponentZenScoreAtStart: Int?
    var userZenScoreAtEnd: Int?
    var opponentZenScoreAtEnd: Int?
    var winner: DuelWinner?
    var resolvedAt: Date?
    var stakesReserved: Bool = false

    init(
        id: UUID = UUID(),
        opponentUsername: String,
        duration: DuelDurationOption,
        durationSeconds: Int,
        stakePoints: Int,
        status: DuelStatus = .pending,
        createdAt: Date,
        startedAt: Date? = nil,
        endsAt: Date? = nil,
        updatedAt: Date? = nil,
        userZenScoreAtStart: Int? = nil,
        opponentZenScoreAtStart: Int? = nil,
        userZenScoreAtEnd: Int? = nil,
        opponentZenScoreAtEnd: Int? = nil,
        winner: DuelWinner? = nil,
        resolvedAt: Date? = nil,
        stakesReserved: Bool = false
    ) {
        self.id = id
        self.opponentUsername = opponentUsername
        self.duration = duration
        self.durationSeconds = durationSeconds
        self.stakePoints = stakePoints
        self.status = status
        self.createdAt = createdAt
        self.startedAt = startedAt
        self.endsAt = endsAt
        self.updatedAt = updatedAt ?? createdAt
        self.userZenScoreAtStart = userZenScoreAtStart
        self.opponentZenScoreAtStart = opponentZenScoreAtStart
        self.userZenScoreAtEnd = userZenScoreAtEnd
        self.opponentZenScoreAtEnd = opponentZenScoreAtEnd
        self.winner = winner
        self.resolvedAt = resolvedAt
        self.stakesReserved = stakesReserved
    }

    var userZenChange: Int? {
        guard let userZenScoreAtStart, let userZenScoreAtEnd else { return nil }
        return userZenScoreAtEnd - userZenScoreAtStart
    }

    var opponentZenChange: Int? {
        guard let opponentZenScoreAtStart, let opponentZenScoreAtEnd else { return nil }
        return opponentZenScoreAtEnd - opponentZenScoreAtStart
    }
}

@Model
final class DuelPointAccount {
    @Attribute(.unique) var accountID: String
    var balance: Int
    var updatedAt: Date

    init(
        accountID: String,
        balance: Int = DuelPointRules.startingBalance,
        updatedAt: Date
    ) {
        self.accountID = accountID
        self.balance = balance
        self.updatedAt = updatedAt
    }
}
