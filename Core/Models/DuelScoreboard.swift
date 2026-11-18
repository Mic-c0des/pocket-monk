import Foundation

/// One side's screen time for a duel: their usual day, and their average day since the duel began.
struct DuelScreenTime: Codable, Equatable, Sendable {
    let baselineMinutes: Int
    let averageDailyMinutes: Int
}

/// Raw screen time for both sides of a started duel, as reported by the duel service.
struct DuelProgress: Equatable, Sendable {
    let me: DuelScreenTime
    let rival: DuelScreenTime
    let updatedAt: Date
}

struct DuelStanding: Equatable, Sendable {
    let name: String
    let monkName: String
    let screenTime: DuelScreenTime
    let zenScore: Int
    let mood: MonkMood

    /// Negative means below baseline, which is the calmer direction.
    var changeFromBaselinePercent: Int {
        guard screenTime.baselineMinutes > 0 else { return 0 }
        let change = Double(screenTime.averageDailyMinutes - screenTime.baselineMinutes)
            / Double(screenTime.baselineMinutes) * 100
        return Int(change.rounded())
    }

    var baselineComparison: String {
        let change = changeFromBaselinePercent
        return switch change {
        case ..<0: "\(abs(change))% below baseline"
        case 0: "Right at baseline"
        default: "\(change)% above baseline"
        }
    }
}

enum DuelLeader: Equatable, Sendable {
    case me
    case rival
    case tied
}

/// The live standing in a duel. Each monk is scored against its own baseline, so a light phone
/// user and a heavy one compete on how much they cut back, not on raw minutes.
/// This is provisional; the final result is settled once the duel ends.
struct DuelScoreboard: Equatable, Sendable {
    let me: DuelStanding
    let rival: DuelStanding
    let updatedAt: Date

    var leader: DuelLeader {
        if me.zenScore == rival.zenScore {
            return .tied
        }
        return me.zenScore > rival.zenScore ? .me : .rival
    }

    static func make(
        progress: DuelProgress,
        me: FriendProfile,
        rival: FriendProfile,
        calculator: ZenScoreCalculator = ZenScoreCalculator()
    ) throws -> DuelScoreboard {
        DuelScoreboard(
            me: try standing(for: me, screenTime: progress.me, calculator: calculator),
            rival: try standing(for: rival, screenTime: progress.rival, calculator: calculator),
            updatedAt: progress.updatedAt
        )
    }

    private static func standing(
        for profile: FriendProfile,
        screenTime: DuelScreenTime,
        calculator: ZenScoreCalculator
    ) throws -> DuelStanding {
        let score = try calculator.calculate(
            screenTimeMinutes: screenTime.averageDailyMinutes,
            baselineMinutes: screenTime.baselineMinutes
        )
        return DuelStanding(
            name: profile.displayName,
            monkName: profile.monkName,
            screenTime: screenTime,
            zenScore: score,
            mood: MonkMood.from(zenScore: score)
        )
    }
}
