import Foundation

enum DuelDurationOption: String, CaseIterable, Identifiable, Sendable {
    case oneDay
    case oneWeek
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .oneDay: "1 day"
        case .oneWeek: "1 week"
        case .custom: "Custom"
        }
    }
}

enum DuelStakeOption: String, CaseIterable, Identifiable, Sendable {
    case braggingRights
    case coffee
    case phoneFreeWalk
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .braggingRights: DuelStake.braggingRights.title
        case .coffee: DuelStake.coffee.title
        case .phoneFreeWalk: DuelStake.phoneFreeWalk.title
        case .custom: "Something else"
        }
    }

    var systemImage: String {
        switch self {
        case .braggingRights: DuelStake.braggingRights.systemImage
        case .coffee: DuelStake.coffee.systemImage
        case .phoneFreeWalk: DuelStake.phoneFreeWalk.systemImage
        case .custom: "pencil"
        }
    }
}

/// The choices made so far in the new-duel flow.
struct DuelDraft: Equatable, Sendable {
    var rival: FriendProfile?
    var durationOption: DuelDurationOption = .oneWeek
    var customDays = 3
    var stakeOption: DuelStakeOption = .braggingRights
    var customStake = ""

    init(rival: FriendProfile? = nil) {
        self.rival = rival
    }

    var duration: DuelDuration {
        switch durationOption {
        case .oneDay: .oneDay
        case .oneWeek: .oneWeek
        case .custom: .custom(days: customDays)
        }
    }

    func stake() throws -> DuelStake {
        switch stakeOption {
        case .braggingRights:
            return .braggingRights
        case .coffee:
            return .coffee
        case .phoneFreeWalk:
            return .phoneFreeWalk
        case .custom:
            return try DuelStake.makeCustom(customStake)
        }
    }

    /// Nil when the step is complete. `busyRivalIDs` are friends who already have an open duel with the user.
    func validationError(for step: DuelCreationStep, busyRivalIDs: Set<UUID> = []) -> DuelError? {
        switch step {
        case .opponent:
            guard let rival else {
                return .noRival
            }
            return busyRivalIDs.contains(rival.id) ? .alreadyDueling(rival.displayName) : nil
        case .duration:
            return duration.isValid ? nil : .invalidDuration
        case .stake:
            do {
                _ = try stake()
                return nil
            } catch {
                return error as? DuelError ?? .emptyStake
            }
        case .review:
            for earlierStep in [DuelCreationStep.opponent, .duration, .stake] {
                if let error = validationError(for: earlierStep, busyRivalIDs: busyRivalIDs) {
                    return error
                }
            }
            return nil
        }
    }

    func makeRequest(busyRivalIDs: Set<UUID> = []) throws -> DuelRequest {
        if let error = validationError(for: .review, busyRivalIDs: busyRivalIDs) {
            throw error
        }
        guard let rival else {
            throw DuelError.noRival
        }
        return DuelRequest(rival: rival, duration: duration, stake: try stake())
    }
}
