import Foundation
import SwiftData

nonisolated enum DuelStatus: String, Codable, Hashable, Sendable {
    case pending
    case active
    case finished
    case declined

    var title: String {
        switch self {
        case .pending: "Waiting for response"
        case .active: "In progress"
        case .finished: "Time complete"
        case .declined: "Declined"
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

nonisolated enum DuelDurationOption: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case oneDay
    case oneWeek
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .oneDay: "1 day"
        case .oneWeek: "1 week"
        case .custom: "Custom window"
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
        return points == 0 ? "No stake" : "\(points) virtual points"
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
            return "Custom · \(days) \(days == 1 ? "day" : "days")"
        }

        let hours = seconds / secondsPerHour
        if hours > 0 {
            return "Custom · \(hours) \(hours == 1 ? "hour" : "hours")"
        }

        let minutes = max(1, seconds / secondsPerMinute)
        return "Custom · \(minutes) \(minutes == 1 ? "minute" : "minutes")"
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

    var errorDescription: String? {
        switch self {
        case .opponentIsNotAFriend:
            "Choose someone from your accepted friends list."
        case .duplicateChallenge:
            "You already have a pending or active duel with this friend."
        case .invalidDuration:
            "Choose an end time after the duel starts."
        case .invalidStake:
            "Choose one of the available virtual point stakes."
        case .challengeNotFound:
            "This challenge is no longer available."
        case .invalidChallengeState:
            "This challenge can’t make that state change."
        case .missingZenScore:
            "Your zen score is unavailable. Try again after your dashboard loads."
        case .invalidZenScore:
            "The zen score must be between 0 and 100."
        case .serviceNotReady:
            "The local duel store isn’t ready yet. Try again."
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
        opponentZenScoreAtStart: Int? = nil
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
    }
}
