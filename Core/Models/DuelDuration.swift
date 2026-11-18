import Foundation

/// How long a duel runs once it starts. A day is a fixed 24 hours so both monks get the same window.
enum DuelDuration: Codable, Hashable, Sendable {
    case oneDay
    case oneWeek
    case custom(days: Int)

    static let customDayRange = 1...30
    private static let secondsPerDay: TimeInterval = 86_400

    var days: Int {
        switch self {
        case .oneDay: 1
        case .oneWeek: 7
        case let .custom(days): days
        }
    }

    var isValid: Bool {
        Self.customDayRange.contains(days)
    }

    var interval: TimeInterval {
        TimeInterval(days) * Self.secondsPerDay
    }

    var title: String {
        switch self {
        case .oneDay: "1 day"
        case .oneWeek: "1 week"
        case let .custom(days): days == 1 ? "1 day" : "\(days) days"
        }
    }

    func endDate(from start: Date) -> Date {
        start.addingTimeInterval(interval)
    }
}
