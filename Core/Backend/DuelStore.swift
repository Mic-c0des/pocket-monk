import Foundation

@MainActor
protocol DuelStoring {
    /// Returns nil when nothing has been saved yet.
    func load() throws -> [Duel]?
    func save(_ duels: [Duel]) throws
}

@MainActor
final class UserDefaultsDuelStore: DuelStoring {
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "pocketMonkDuels") {
        self.defaults = defaults
        self.key = key
    }

    func load() throws -> [Duel]? {
        guard let data = defaults.data(forKey: key) else {
            return nil
        }
        return try JSONDecoder().decode([Duel].self, from: data)
    }

    func save(_ duels: [Duel]) throws {
        defaults.set(try JSONEncoder().encode(duels), forKey: key)
    }
}

@MainActor
final class InMemoryDuelStore: DuelStoring {
    private(set) var duels: [Duel]?

    init(duels: [Duel]? = nil) {
        self.duels = duels
    }

    func load() throws -> [Duel]? {
        duels
    }

    func save(_ duels: [Duel]) throws {
        self.duels = duels
    }
}
