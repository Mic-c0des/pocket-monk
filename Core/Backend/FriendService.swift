import Foundation
import SwiftData

@MainActor
protocol FriendServicing {
    func loadFriends() throws -> [FriendRecord]
    func addByUsername(_ username: String, now: Date) throws -> FriendRecord
    func addByInviteLink(_ url: URL, now: Date) throws -> FriendRecord
    func createInviteLink(now: Date) throws -> URL
    func createDemoIncomingRequest(now: Date) throws -> FriendRecord
    func acceptIncomingRequest(id: UUID, now: Date) throws
    func declineIncomingRequest(id: UUID, now: Date) throws
}

@MainActor
final class LocalFriendService: FriendServicing {
    private static let currentUsername = "you"
    private static let demoDirectory = ["ava", "kai", "luna", "noah", "sage"]

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadFriends() throws -> [FriendRecord] {
        try modelContext.fetch(
            FetchDescriptor<FriendRecord>(sortBy: [SortDescriptor(\.createdAt)])
        )
    }

    func addByUsername(_ username: String, now: Date = .now) throws -> FriendRecord {
        guard let username = FriendUsername.normalize(username) else {
            throw FriendServiceError.invalidUsername
        }
        guard username != Self.currentUsername else {
            throw FriendServiceError.cannotAddYourself
        }
        guard Self.demoDirectory.contains(username) else {
            throw FriendServiceError.usernameNotFound
        }

        let friends = try loadFriends()
        try ensureNoActiveRelationship(with: username, in: friends)
        let friend = FriendRecord(
            username: username,
            status: .pendingOutgoing,
            createdAt: now
        )
        modelContext.insert(friend)
        try modelContext.save()
        return friend
    }

    func addByInviteLink(_ url: URL, now: Date = .now) throws -> FriendRecord {
        let invite = try FriendInviteLink.parse(url, now: now)
        guard invite.username != Self.currentUsername else {
            throw FriendServiceError.cannotAddYourself
        }

        let friends = try loadFriends()
        try ensureNoActiveRelationship(with: invite.username, in: friends)
        let friend = FriendRecord(
            username: invite.username,
            status: .pendingOutgoing,
            createdAt: now
        )
        modelContext.insert(friend)
        try modelContext.save()
        return friend
    }

    func createInviteLink(now: Date = .now) throws -> URL {
        try FriendInviteLink.make(username: Self.currentUsername, now: now)
    }

    func createDemoIncomingRequest(now: Date = .now) throws -> FriendRecord {
        let friends = try loadFriends()
        guard let username = Self.demoDirectory.first(where: { candidate in
            candidate != Self.currentUsername
                && !friends.contains {
                    $0.username == candidate && $0.status != .declined
                }
        }) else {
            throw FriendServiceError.usernameNotFound
        }

        let request = FriendRecord(
            username: username,
            status: .pendingIncoming,
            createdAt: now
        )
        modelContext.insert(request)
        try modelContext.save()
        return request
    }

    func acceptIncomingRequest(id: UUID, now: Date = .now) throws {
        try updateIncomingRequest(id: id, status: .friends, now: now)
    }

    func declineIncomingRequest(id: UUID, now: Date = .now) throws {
        try updateIncomingRequest(id: id, status: .declined, now: now)
    }

    private func ensureNoActiveRelationship(
        with username: String,
        in friends: [FriendRecord]
    ) throws {
        guard !friends.contains(where: {
            $0.username == username && $0.status != .declined
        }) else {
            throw FriendServiceError.duplicateFriend
        }
    }

    private func updateIncomingRequest(
        id: UUID,
        status: FriendRelationshipStatus,
        now: Date
    ) throws {
        guard let request = try loadFriends().first(where: { $0.id == id }),
              request.status == .pendingIncoming else {
            throw FriendServiceError.incomingRequestNotFound
        }

        request.status = status
        request.updatedAt = now
        try modelContext.save()
    }
}
