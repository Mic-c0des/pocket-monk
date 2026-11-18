import Foundation

@MainActor
protocol FriendshipStoring {
    /// Returns nil when nothing has been saved yet.
    func load() throws -> [Friendship]?
    func save(_ friendships: [Friendship]) throws
}

@MainActor
final class UserDefaultsFriendshipStore: FriendshipStoring {
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "pocketMonkFriendships") {
        self.defaults = defaults
        self.key = key
    }

    func load() throws -> [Friendship]? {
        guard let data = defaults.data(forKey: key) else {
            return nil
        }
        return try JSONDecoder().decode([Friendship].self, from: data)
    }

    func save(_ friendships: [Friendship]) throws {
        defaults.set(try JSONEncoder().encode(friendships), forKey: key)
    }
}

@MainActor
final class InMemoryFriendshipStore: FriendshipStoring {
    private(set) var friendships: [Friendship]?

    init(friendships: [Friendship]? = nil) {
        self.friendships = friendships
    }

    func load() throws -> [Friendship]? {
        friendships
    }

    func save(_ friendships: [Friendship]) throws {
        self.friendships = friendships
    }
}
