import Foundation

/// Stands in for account services until a backend is chosen: the user directory and invites
/// are sample data, while the friend list itself persists on this device.
@MainActor
final class LocalFriendsService: FriendsServicing {
    private let currentUser: FriendProfile
    private let directory: [FriendProfile]
    private let invites: [FriendInvite]
    private let store: any FriendshipStoring
    private let now: () -> Date
    private let ownInviteCode = FriendInviteCode.random()
    private var cachedGraph: FriendGraph?

    init(
        currentUser: FriendProfile = SampleFriendsData.guest,
        directory: [FriendProfile] = SampleFriendsData.directory,
        invites: [FriendInvite]? = nil,
        store: (any FriendshipStoring)? = nil,
        now: @escaping () -> Date = { .now }
    ) {
        self.currentUser = currentUser
        self.directory = directory
        self.invites = invites ?? SampleFriendsData.invites(relativeTo: now())
        self.store = store ?? UserDefaultsFriendshipStore()
        self.now = now
    }

    func loadFriendships() async throws -> [Friendship] {
        try currentGraph().friendships
    }

    func sendRequest(toUsername input: String) async throws -> [Friendship] {
        let username = try Username.normalize(input)
        guard username != currentUser.username else {
            throw FriendGraphError.cannotAddSelf
        }
        guard let profile = directory.first(where: { $0.username == username }) else {
            throw FriendsServiceError.userNotFound(username)
        }
        return try update { graph in
            _ = try graph.sendRequest(to: profile, from: currentUser, at: now())
        }
    }

    func connect(usingInvite code: FriendInviteCode) async throws -> [Friendship] {
        guard code != ownInviteCode else {
            throw FriendInviteError.ownInvite
        }
        guard let invite = invites.first(where: { $0.code == code }) else {
            throw FriendInviteError.notFound
        }
        guard !invite.isExpired(at: now()) else {
            throw FriendInviteError.expired
        }
        return try update { graph in
            _ = try graph.connect(viaInviteFrom: invite.inviter, as: currentUser, at: now())
        }
    }

    func acceptRequest(from profileID: UUID) async throws -> [Friendship] {
        try update { graph in
            _ = try graph.acceptRequest(from: profileID, at: now())
        }
    }

    func declineRequest(from profileID: UUID) async throws -> [Friendship] {
        try update { try $0.declineRequest(from: profileID) }
    }

    func cancelRequest(to profileID: UUID) async throws -> [Friendship] {
        try update { try $0.cancelRequest(to: profileID) }
    }

    func removeFriend(_ profileID: UUID) async throws -> [Friendship] {
        try update { try $0.removeFriend(profileID) }
    }

    func inviteLink() async throws -> URL {
        guard let url = FriendInviteLink.url(for: ownInviteCode) else {
            throw FriendInviteError.linkUnavailable
        }
        return url
    }

    private func currentGraph() throws -> FriendGraph {
        if let cachedGraph {
            return cachedGraph
        }
        let saved = try store.load()
        let graph = FriendGraph(
            friendships: saved ?? SampleFriendsData.initialFriendships(relativeTo: now())
        )
        cachedGraph = graph
        return graph
    }

    private func update(_ change: (inout FriendGraph) throws -> Void) throws -> [Friendship] {
        var graph = try currentGraph()
        try change(&graph)
        // Save before caching so a failed write leaves the visible list unchanged.
        try store.save(graph.friendships)
        cachedGraph = graph
        return graph.friendships
    }
}
