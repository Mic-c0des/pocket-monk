import Combine
import Foundation

@MainActor
final class FriendsViewModel: ObservableObject {
    @Published private(set) var state: FriendsViewState = .loading
    @Published private(set) var inviteLink: URL?
    @Published private(set) var processingProfileIDs: Set<UUID> = []
    @Published private(set) var isAddingFriend = false
    @Published private(set) var addFriendErrorMessage: String?
    @Published private(set) var actionErrorMessage: String?

    private let service: any FriendsServicing

    init(service: any FriendsServicing = LocalFriendsService()) {
        self.service = service
    }

    var graph: FriendGraph? {
        if case let .loaded(graph) = state { graph } else { nil }
    }

    func isProcessing(_ profileID: UUID) -> Bool {
        processingProfileIDs.contains(profileID)
    }

    func load() async {
        // Refreshing keeps the current list on screen instead of flashing a spinner.
        let hasLoaded = graph != nil
        if !hasLoaded {
            state = .loading
        }

        do {
            try Task.checkCancellation()
            let friendships = try await service.loadFriendships()
            try Task.checkCancellation()
            state = .loaded(FriendGraph(friendships: friendships))
        } catch is CancellationError {
            return
        } catch {
            if hasLoaded {
                actionErrorMessage = error.localizedDescription
            } else {
                state = .failed(error.localizedDescription)
            }
        }

        if inviteLink == nil {
            inviteLink = try? await service.inviteLink()
        }
    }

    /// Returns true when the friend was added or a request was sent.
    func addFriend(_ input: String, method: AddFriendMethod) async -> Bool {
        guard !isAddingFriend else { return false }

        isAddingFriend = true
        addFriendErrorMessage = nil
        defer { isAddingFriend = false }

        do {
            let friendships: [Friendship]
            switch method {
            case .username:
                friendships = try await service.sendRequest(toUsername: input)
            case .inviteLink:
                friendships = try await service.connect(usingInvite: FriendInviteLink.parse(input))
            }
            state = .loaded(FriendGraph(friendships: friendships))
            return true
        } catch {
            addFriendErrorMessage = error.localizedDescription
            return false
        }
    }

    func clearAddFriendError() {
        addFriendErrorMessage = nil
    }

    func dismissActionError() {
        actionErrorMessage = nil
    }

    func acceptRequest(from profileID: UUID) async {
        await perform(on: profileID) {
            try await self.service.acceptRequest(from: profileID)
        }
    }

    func declineRequest(from profileID: UUID) async {
        await perform(on: profileID) {
            try await self.service.declineRequest(from: profileID)
        }
    }

    func cancelRequest(to profileID: UUID) async {
        await perform(on: profileID) {
            try await self.service.cancelRequest(to: profileID)
        }
    }

    func removeFriend(_ profileID: UUID) async {
        await perform(on: profileID) {
            try await self.service.removeFriend(profileID)
        }
    }

    private func perform(
        on profileID: UUID,
        _ operation: () async throws -> [Friendship]
    ) async {
        guard !processingProfileIDs.contains(profileID) else { return }

        processingProfileIDs.insert(profileID)
        actionErrorMessage = nil
        defer { processingProfileIDs.remove(profileID) }

        do {
            state = .loaded(FriendGraph(friendships: try await operation()))
        } catch {
            actionErrorMessage = error.localizedDescription
        }
    }
}
