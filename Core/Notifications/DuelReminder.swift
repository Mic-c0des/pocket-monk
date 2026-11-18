import Foundation

/// The local notification sent when a duel's window closes.
struct DuelReminder: Equatable, Sendable {
    let identifier: String
    let title: String
    let body: String
    let fireDate: Date

    static func identifier(for duelID: UUID) -> String {
        "duel-end-\(duelID.uuidString)"
    }

    /// Nil unless the duel is running at `date`; there is nothing to remind about otherwise.
    static func endOfDuel(_ duel: Duel, at date: Date) -> DuelReminder? {
        guard duel.status(at: date) == .active, let endsAt = duel.endsAt else {
            return nil
        }
        return DuelReminder(
            identifier: identifier(for: duel.id),
            title: "Your duel with \(duel.rival.displayName) is over",
            body: "Time’s up. See whose monk stayed calmer.",
            fireDate: endsAt
        )
    }
}
