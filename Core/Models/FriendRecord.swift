import Foundation
import SwiftData

nonisolated enum FriendRelationshipStatus: String, Codable, Sendable {
    case pendingIncoming
    case pendingOutgoing
    case friends
    case declined

    var title: String {
        switch self {
        case .pendingIncoming: "Incoming request"
        case .pendingOutgoing: "Request sent"
        case .friends: "Friend"
        case .declined: "Declined"
        }
    }

    var systemImage: String {
        switch self {
        case .pendingIncoming: "person.crop.circle.badge.questionmark"
        case .pendingOutgoing: "clock"
        case .friends: "person.crop.circle.badge.checkmark"
        case .declined: "person.crop.circle.badge.xmark"
        }
    }
}

@Model
final class FriendRecord {
    @Attribute(.unique) var id: UUID
    var username: String
    var status: FriendRelationshipStatus
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        username: String,
        status: FriendRelationshipStatus,
        createdAt: Date,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.username = username
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
    }
}

nonisolated enum FriendUsername {
    static let minimumLength = 3
    static let maximumLength = 20

    static func normalize(_ username: String) -> String? {
        let normalizedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard (minimumLength...maximumLength).contains(normalizedUsername.count),
              normalizedUsername.allSatisfy({
                  $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "_")
              })
        else {
            return nil
        }
        return normalizedUsername
    }
}

nonisolated enum FriendServiceError: LocalizedError, Equatable, Sendable {
    case invalidUsername
    case usernameNotFound
    case duplicateFriend
    case invalidInviteLink
    case expiredInviteLink
    case cannotAddYourself
    case incomingRequestNotFound
    case serviceNotReady

    var errorDescription: String? {
        switch self {
        case .invalidUsername:
            "Enter a username with 3–20 letters, numbers, or underscores."
        case .usernameNotFound:
            "That username isn’t in the local demo directory."
        case .duplicateFriend:
            "You already have an active request or friendship with this person."
        case .invalidInviteLink:
            "This invite link isn’t valid. Check the link and try again."
        case .expiredInviteLink:
            "This invite link has expired. Ask for a new one."
        case .cannotAddYourself:
            "You can’t add your own account."
        case .incomingRequestNotFound:
            "This incoming request is no longer available."
        case .serviceNotReady:
            "The local friends store isn’t ready yet. Try again."
        }
    }
}
