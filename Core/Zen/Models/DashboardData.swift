import Foundation

struct DashboardData: Equatable, Sendable {
    let monk: Monk
    let todayScreenTimeMinutes: Int
    let baselineAverageMinutes: Int
    let recentDays: [DailyScreenTime]
    let lastUpdatedAt: Date
}

struct DashboardSnapshot: Equatable, Sendable {
    let monk: Monk
    let mood: MonkMood
    let zenScore: Int
    let todayScreenTimeMinutes: Int
    let baselineAverageMinutes: Int
    let recentDays: [DailyScreenTime]
    let isStale: Bool

    var differenceFromBaselineMinutes: Int {
        todayScreenTimeMinutes - baselineAverageMinutes
    }

    var baselineComparisonMessage: String {
        switch differenceFromBaselineMinutes {
        case ..<0:
            "\(abs(differenceFromBaselineMinutes)) min below your baseline"
        case 0:
            "Right at your daily baseline"
        default:
            "\(differenceFromBaselineMinutes) min above your baseline"
        }
    }
}

enum DashboardFreshness {
    static let staleAfter: TimeInterval = 86_400

    static func isStale(lastUpdatedAt: Date, now: Date) -> Bool {
        now.timeIntervalSince(lastUpdatedAt) > staleAfter
    }
}
