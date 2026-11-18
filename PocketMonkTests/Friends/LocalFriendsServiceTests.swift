import Foundation
import Testing
@testable import Pocket_Monk

@MainActor
struct LocalFriendsServiceTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func makeService(
        store: any FriendshipStoring = InMemoryFriendshipStore()
    ) -> LocalFriendsService {
        LocalFriendsService(store: store, now: { [now] in now })
    }

    @Test func seedsSampleFriendshipsOnFirstLoad() async throws {
        let graph = FriendGraph(friendships: try await makeService().loadFriendships())

        #expect(graph.friends.map(\.id) == [SampleFriendsData.sage.id])
        #expect(graph.incomingRequests.map(\.id) == [SampleFriendsData.juniper.id])
    }

    @Test func savedFriendshipsPersistAcrossInstances() async throws {
        let store = InMemoryFriendshipStore()
        _ = try await makeService(store: store).sendRequest(toUsername: "@Noor")

        let reloaded = FriendGraph(friendships: try await makeService(store: store).loadFriendships())
        #expect(reloaded.outgoingRequests.map(\.id) == [SampleFriendsData.noor.id])
    }

    @Test func unknownUsernameThrows() async {
        await #expect(throws: FriendsServiceError.userNotFound("nobody")) {
            try await makeService().sendRequest(toUsername: "nobody")
        }
    }

    @Test func requestingOwnUsernameThrows() async {
        await #expect(throws: FriendGraphError.cannotAddSelf) {
            try await makeService().sendRequest(toUsername: SampleFriendsData.guest.username)
        }
    }

    @Test func validInviteAddsInviterAsFriend() async throws {
        let friendships = try await makeService().connect(usingInvite: FriendInviteCode("RIVER123"))
        #expect(FriendGraph(friendships: friendships).friends.contains { $0.id == SampleFriendsData.river.id })
    }

    @Test func expiredInviteThrows() async {
        await #expect(throws: FriendInviteError.expired) {
            try await makeService().connect(usingInvite: FriendInviteCode("KAILEE01"))
        }
    }

    @Test func unknownInviteThrows() async {
        await #expect(throws: FriendInviteError.notFound) {
            try await makeService().connect(usingInvite: FriendInviteCode("ZZZZ9999"))
        }
    }

    @Test func ownInviteThrows() async throws {
        let service = makeService()
        let code = try FriendInviteLink.parse(try await service.inviteLink().absoluteString)

        await #expect(throws: FriendInviteError.ownInvite) {
            try await service.connect(usingInvite: code)
        }
    }

    @Test func failedSaveLeavesFriendshipsUnchanged() async throws {
        let service = makeService(store: FailingSaveStore())
        let before = try await service.loadFriendships()

        await #expect(throws: FailingSaveStore.SaveError.self) {
            try await service.sendRequest(toUsername: "noor")
        }
        #expect(try await service.loadFriendships() == before)
    }
}

@MainActor
private final class FailingSaveStore: FriendshipStoring {
    struct SaveError: Error {}

    func load() throws -> [Friendship]? {
        nil
    }

    func save(_ friendships: [Friendship]) throws {
        throw SaveError()
    }
}
