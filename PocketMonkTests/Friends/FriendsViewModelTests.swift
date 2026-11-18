import Foundation
import Testing
@testable import Pocket_Monk

@MainActor
struct FriendsViewModelTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func makeViewModel(
        store: any FriendshipStoring = InMemoryFriendshipStore()
    ) -> FriendsViewModel {
        FriendsViewModel(service: LocalFriendsService(store: store, now: { [now] in now }))
    }

    @Test func loadShowsFriendsAndInviteLink() async {
        let viewModel = makeViewModel()
        await viewModel.load()

        #expect(viewModel.graph?.friends.count == 1)
        #expect(viewModel.graph?.incomingRequests.count == 1)
        #expect(viewModel.inviteLink != nil)
    }

    @Test func loadFailureShowsFailedState() async {
        let viewModel = makeViewModel(store: CorruptStore())
        await viewModel.load()

        guard case .failed = viewModel.state else {
            Issue.record("Expected a failed state, got \(viewModel.state)")
            return
        }
    }

    @Test func addingByUsernameShowsSentRequest() async {
        let viewModel = makeViewModel()
        await viewModel.load()

        let added = await viewModel.addFriend("noor", method: .username)

        #expect(added)
        #expect(viewModel.graph?.outgoingRequests.map(\.id) == [SampleFriendsData.noor.id])
        #expect(viewModel.addFriendErrorMessage == nil)
        #expect(!viewModel.isAddingFriend)
    }

    @Test func addingUnknownUsernameShowsError() async {
        let viewModel = makeViewModel()
        await viewModel.load()

        let added = await viewModel.addFriend("nobody", method: .username)

        #expect(!added)
        #expect(
            viewModel.addFriendErrorMessage
                == FriendsServiceError.userNotFound("nobody").localizedDescription
        )
    }

    @Test func addingByInviteLinkAddsFriend() async {
        let viewModel = makeViewModel()
        await viewModel.load()

        let added = await viewModel.addFriend(
            "https://pocketmonk.app/invite/RIVER123",
            method: .inviteLink
        )

        #expect(added)
        #expect(viewModel.graph?.friends.contains { $0.id == SampleFriendsData.river.id } == true)
    }

    @Test func expiredInviteShowsError() async {
        let viewModel = makeViewModel()
        await viewModel.load()

        let added = await viewModel.addFriend("KAILEE01", method: .inviteLink)

        #expect(!added)
        #expect(viewModel.addFriendErrorMessage == FriendInviteError.expired.localizedDescription)
    }

    @Test func acceptingRequestMovesItToFriends() async {
        let viewModel = makeViewModel()
        await viewModel.load()

        await viewModel.acceptRequest(from: SampleFriendsData.juniper.id)

        #expect(viewModel.graph?.incomingRequests.isEmpty == true)
        #expect(viewModel.graph?.friends.contains { $0.id == SampleFriendsData.juniper.id } == true)
        #expect(!viewModel.isProcessing(SampleFriendsData.juniper.id))
    }

    @Test func invalidActionShowsActionError() async {
        let viewModel = makeViewModel()
        await viewModel.load()

        await viewModel.removeFriend(SampleFriendsData.juniper.id)

        #expect(viewModel.actionErrorMessage == FriendGraphError.friendNotFound.localizedDescription)
        viewModel.dismissActionError()
        #expect(viewModel.actionErrorMessage == nil)
    }
}

@MainActor
private final class CorruptStore: FriendshipStoring {
    struct LoadError: Error {}

    func load() throws -> [Friendship]? {
        throw LoadError()
    }

    func save(_ friendships: [Friendship]) throws {}
}
