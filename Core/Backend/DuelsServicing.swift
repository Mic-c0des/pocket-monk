import Foundation

/// Every mutation returns the full, updated list so callers always render the service's truth.
@MainActor
protocol DuelsServicing {
    func loadDuels() async throws -> [Duel]
    func createDuel(_ request: DuelRequest) async throws -> [Duel]
    func acceptDuel(_ duelID: UUID) async throws -> [Duel]
    func declineDuel(_ duelID: UUID) async throws -> [Duel]
    func cancelDuel(_ duelID: UUID) async throws -> [Duel]
    /// Screen time for both sides since the duel started; throws `DuelError.notStarted` for pending duels.
    func loadProgress(for duel: Duel) async throws -> DuelProgress
}
