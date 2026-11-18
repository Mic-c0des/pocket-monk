import Foundation
import Testing
@testable import Pocket_Monk

@MainActor
struct FriendGraphTests {
    private let me = FriendProfile(username: "me", displayName: "Me", monkName: "Milo")
    private let sage = FriendProfile(username: "sage", displayName: "Sage Rivera", monkName: "Pebble")
    private let ash = FriendProfile(username: "ash", displayName: "Ash Moreno", monkName: "Cedar")
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    private func makeGraph(_ entries: (FriendProfile, FriendshipStatus)...) -> FriendGraph {
        FriendGraph(friendships: entries.map { Friendship(profile: $0.0, status: $0.1, updatedAt: date) })
    }

    @Test func sendingRequestCreatesOutgoingRequest() throws {
        var graph = FriendGraph()
        try graph.sendRequest(to: sage, from: me, at: date)

        #expect(graph.outgoingRequests.map(\.id) == [sage.id])
        #expect(graph.friends.isEmpty)
    }

    @Test func sendingDuplicateRequestThrows() throws {
        var graph = makeGraph((sage, .outgoing))
        #expect(throws: FriendGraphError.requestAlreadySent) {
            try graph.sendRequest(to: sage, from: me, at: date)
        }
    }

    @Test func requestingExistingFriendThrows() {
        var graph = makeGraph((sage, .accepted))
        #expect(throws: FriendGraphError.alreadyFriends) {
            try graph.sendRequest(to: sage, from: me, at: date)
        }
    }

    @Test func cannotRequestYourself() {
        var graph = FriendGraph()
        #expect(throws: FriendGraphError.cannotAddSelf) {
            try graph.sendRequest(to: me, from: me, at: date)
        }
    }

    @Test func requestingSomeoneWhoAskedYouAcceptsTheirRequest() throws {
        var graph = makeGraph((sage, .incoming))
        let friendship = try graph.sendRequest(to: sage, from: me, at: date)

        #expect(friendship.status == .accepted)
        #expect(graph.incomingRequests.isEmpty)
        #expect(graph.friends.map(\.id) == [sage.id])
    }

    @Test func acceptingRequestMovesItToFriends() throws {
        var graph = makeGraph((sage, .incoming))
        let later = date.addingTimeInterval(60)
        try graph.acceptRequest(from: sage.id, at: later)

        #expect(graph.friends.first?.updatedAt == later)
        #expect(graph.incomingRequests.isEmpty)
    }

    @Test func acceptingWithoutIncomingRequestThrows() {
        var graph = makeGraph((sage, .outgoing))
        #expect(throws: FriendGraphError.requestNotFound) {
            try graph.acceptRequest(from: sage.id, at: date)
        }
    }

    @Test func decliningRequestRemovesIt() throws {
        var graph = makeGraph((sage, .incoming))
        try graph.declineRequest(from: sage.id)
        #expect(graph.isEmpty)
    }

    @Test func cancellingOnlyAppliesToOutgoingRequests() throws {
        var graph = makeGraph((sage, .outgoing), (ash, .accepted))
        try graph.cancelRequest(to: sage.id)

        #expect(graph.outgoingRequests.isEmpty)
        #expect(throws: FriendGraphError.requestNotFound) {
            try graph.cancelRequest(to: ash.id)
        }
    }

    @Test func removingFriendOnlyAppliesToAcceptedFriends() throws {
        var graph = makeGraph((sage, .accepted), (ash, .incoming))
        try graph.removeFriend(sage.id)

        #expect(graph.friends.isEmpty)
        #expect(throws: FriendGraphError.friendNotFound) {
            try graph.removeFriend(ash.id)
        }
    }

    @Test func inviteConnectsImmediatelyEvenWithPendingRequest() throws {
        var graph = makeGraph((sage, .outgoing))
        try graph.connect(viaInviteFrom: sage, as: me, at: date)

        #expect(graph.friends.map(\.id) == [sage.id])
        #expect(graph.outgoingRequests.isEmpty)
    }

    @Test func inviteFromExistingFriendThrows() {
        var graph = makeGraph((sage, .accepted))
        #expect(throws: FriendGraphError.alreadyFriends) {
            try graph.connect(viaInviteFrom: sage, as: me, at: date)
        }
    }

    @Test func duplicateRecordsKeepTheMostRecent() {
        let graph = FriendGraph(friendships: [
            Friendship(profile: sage, status: .accepted, updatedAt: date.addingTimeInterval(60)),
            Friendship(profile: sage, status: .outgoing, updatedAt: date),
        ])

        #expect(graph.friendships.count == 1)
        #expect(graph.friends.map(\.id) == [sage.id])
    }

    @Test func friendsAreSortedByDisplayName() {
        let graph = makeGraph((sage, .accepted), (ash, .accepted))
        #expect(graph.friends.map(\.profile.displayName) == ["Ash Moreno", "Sage Rivera"])
    }
}
