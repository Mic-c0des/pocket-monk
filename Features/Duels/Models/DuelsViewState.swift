import Foundation

enum DuelsViewState: Equatable, Sendable {
    case loading
    case loaded(DuelBook)
    case failed(String)
}

enum DuelScoreboardState: Equatable, Sendable {
    case loading
    case loaded(DuelScoreboard)
    case failed(String)
}
