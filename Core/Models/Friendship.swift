import Foundation

enum FriendshipStatus: String, Codable, Sendable {
    case incoming
    case outgoing
    case accepted
}

/// The current user's relationship with one other person; there is at most one per profile.
struct Friendship: Codable, Equatable, Identifiable, Sendable {
    let profile: FriendProfile
    let status: FriendshipStatus
    let updatedAt: Date

    var id: UUID { profile.id }
}
