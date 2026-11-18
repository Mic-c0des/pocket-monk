import Foundation

/// Stands in for duel services until a backend is chosen. Duels persist on this device and
/// rivals' screen time is sample data. Challenges you send stay pending, since no one else
/// can accept them until accounts exist.
@MainActor
final class LocalDuelsService: DuelsServicing {
    private let currentUser: FriendProfile
    private let friendsService: any FriendsServicing
    private let store: any DuelStoring
    private let now: () -> Date
    private var cachedBook: DuelBook?

    /// Pass the same friends service the Friends tab uses so new friends can be challenged right away.
    init(
        currentUser: FriendProfile = SampleFriendsData.guest,
        friendsService: (any FriendsServicing)? = nil,
        store: (any DuelStoring)? = nil,
        now: @escaping () -> Date = { .now }
    ) {
        self.currentUser = currentUser
        self.friendsService = friendsService ?? LocalFriendsService(currentUser: currentUser, now: now)
        self.store = store ?? UserDefaultsDuelStore()
        self.now = now
    }

    func loadDuels() async throws -> [Duel] {
        try currentBook().duels
    }

    func createDuel(_ request: DuelRequest) async throws -> [Duel] {
        let friends = FriendGraph(friendships: try await friendsService.loadFriendships())
            .friends
            .map(\.profile)
        return try update { book in
            _ = try book.create(request, by: currentUser, friends: friends, at: now())
        }
    }

    func acceptDuel(_ duelID: UUID) async throws -> [Duel] {
        try update { book in
            _ = try book.accept(duelID, at: now())
        }
    }

    func declineDuel(_ duelID: UUID) async throws -> [Duel] {
        try update { try $0.decline(duelID) }
    }

    func cancelDuel(_ duelID: UUID) async throws -> [Duel] {
        try update { try $0.cancel(duelID) }
    }

    func loadProgress(for duel: Duel) async throws -> DuelProgress {
        guard !duel.isPending else {
            throw DuelError.notStarted
        }
        return SampleDuelsData.progress(against: duel.rival, updatedAt: now())
    }

    private func currentBook() throws -> DuelBook {
        if let cachedBook {
            return cachedBook
        }
        let saved = try store.load()
        let book = DuelBook(duels: saved ?? SampleDuelsData.initialDuels(relativeTo: now()))
        cachedBook = book
        return book
    }

    private func update(_ change: (inout DuelBook) throws -> Void) throws -> [Duel] {
        var book = try currentBook()
        try change(&book)
        // Save before caching so a failed write leaves the visible list unchanged.
        try store.save(book.duels)
        cachedBook = book
        return book.duels
    }
}
