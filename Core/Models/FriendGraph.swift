import Foundation

/// The current user's friends and requests, with the rules for moving between states.
struct FriendGraph: Equatable, Sendable {
    private(set) var friendships: [Friendship]

    init(friendships: [Friendship] = []) {
        // One relationship per person; when records collide, the most recent wins.
        var latestByProfile: [UUID: Friendship] = [:]
        for friendship in friendships {
            if let existing = latestByProfile[friendship.id],
               existing.updatedAt > friendship.updatedAt {
                continue
            }
            latestByProfile[friendship.id] = friendship
        }
        self.friendships = latestByProfile.values.sorted {
            $0.profile.username < $1.profile.username
        }
    }

    var isEmpty: Bool {
        friendships.isEmpty
    }

    var friends: [Friendship] {
        friendships
            .filter { $0.status == .accepted }
            .sorted {
                $0.profile.displayName.localizedCaseInsensitiveCompare($1.profile.displayName)
                    == .orderedAscending
            }
    }

    var incomingRequests: [Friendship] {
        requests(with: .incoming)
    }

    var outgoingRequests: [Friendship] {
        requests(with: .outgoing)
    }

    func friendship(with profileID: UUID) -> Friendship? {
        friendships.first { $0.id == profileID }
    }

    @discardableResult
    mutating func sendRequest(
        to profile: FriendProfile,
        from currentUser: FriendProfile,
        at date: Date
    ) throws -> Friendship {
        guard profile.id != currentUser.id else {
            throw FriendGraphError.cannotAddSelf
        }

        switch friendship(with: profile.id)?.status {
        case .accepted:
            throw FriendGraphError.alreadyFriends
        case .outgoing:
            throw FriendGraphError.requestAlreadySent
        case .incoming:
            // They already asked, so asking back completes the friendship.
            return try acceptRequest(from: profile.id, at: date)
        case nil:
            return upsert(Friendship(profile: profile, status: .outgoing, updatedAt: date))
        }
    }

    @discardableResult
    mutating func connect(
        viaInviteFrom inviter: FriendProfile,
        as currentUser: FriendProfile,
        at date: Date
    ) throws -> Friendship {
        guard inviter.id != currentUser.id else {
            throw FriendGraphError.cannotAddSelf
        }
        guard friendship(with: inviter.id)?.status != .accepted else {
            throw FriendGraphError.alreadyFriends
        }

        // Sharing an invite link is the inviter's consent, so no separate request is needed.
        return upsert(Friendship(profile: inviter, status: .accepted, updatedAt: date))
    }

    @discardableResult
    mutating func acceptRequest(from profileID: UUID, at date: Date) throws -> Friendship {
        guard let request = friendship(with: profileID), request.status == .incoming else {
            throw FriendGraphError.requestNotFound
        }
        return upsert(Friendship(profile: request.profile, status: .accepted, updatedAt: date))
    }

    mutating func declineRequest(from profileID: UUID) throws {
        guard friendship(with: profileID)?.status == .incoming else {
            throw FriendGraphError.requestNotFound
        }
        friendships.removeAll { $0.id == profileID }
    }

    mutating func cancelRequest(to profileID: UUID) throws {
        guard friendship(with: profileID)?.status == .outgoing else {
            throw FriendGraphError.requestNotFound
        }
        friendships.removeAll { $0.id == profileID }
    }

    mutating func removeFriend(_ profileID: UUID) throws {
        guard friendship(with: profileID)?.status == .accepted else {
            throw FriendGraphError.friendNotFound
        }
        friendships.removeAll { $0.id == profileID }
    }

    private func requests(with status: FriendshipStatus) -> [Friendship] {
        friendships
            .filter { $0.status == status }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    private mutating func upsert(_ friendship: Friendship) -> Friendship {
        friendships.removeAll { $0.id == friendship.id }
        friendships.append(friendship)
        return friendship
    }
}

enum FriendGraphError: LocalizedError, Equatable, Sendable {
    case cannotAddSelf
    case alreadyFriends
    case requestAlreadySent
    case requestNotFound
    case friendNotFound

    var errorDescription: String? {
        switch self {
        case .cannotAddSelf:
            "You can’t add yourself as a friend."
        case .alreadyFriends:
            "You’re already friends."
        case .requestAlreadySent:
            "You’ve already sent this person a request."
        case .requestNotFound:
            "That request is no longer available."
        case .friendNotFound:
            "That friend is no longer in your circle."
        }
    }
}
