import Foundation

nonisolated enum LiveActivityUpdateCadence {
    static let minimumInterval: TimeInterval = 15 * 60

    static func shouldUpdate(lastUpdatedAt: Date, now: Date) -> Bool {
        now.timeIntervalSince(lastUpdatedAt) >= minimumInterval
    }
}
