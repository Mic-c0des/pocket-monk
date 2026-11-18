import Foundation

/// Every mutation returns the full, updated list so callers always render the service's truth.
@MainActor
protocol FriendsServicing {
    func loadFriendships() async throws -> [Friendship]
    func sendRequest(toUsername username: String) async throws -> [Friendship]
    func connect(usingInvite code: FriendInviteCode) async throws -> [Friendship]
    func acceptRequest(from profileID: UUID) async throws -> [Friendship]
    func declineRequest(from profileID: UUID) async throws -> [Friendship]
    func cancelRequest(to profileID: UUID) async throws -> [Friendship]
    func removeFriend(_ profileID: UUID) async throws -> [Friendship]
    func inviteLink() async throws -> URL
}

enum FriendsServiceError: LocalizedError, Equatable, Sendable {
    case userNotFound(String)

    var errorDescription: String? {
        switch self {
        case let .userNotFound(username):
            "We couldn’t find anyone with the username @\(username)."
        }
    }
}
