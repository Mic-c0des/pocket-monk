import Foundation

enum AddFriendMethod: String, CaseIterable, Identifiable, Sendable {
    case username
    case inviteLink

    var id: String { rawValue }

    var title: String {
        switch self {
        case .username: "Username"
        case .inviteLink: "Invite link"
        }
    }

    var prompt: String {
        switch self {
        case .username: "Enter your friend’s Pocket Monk username."
        case .inviteLink: "Paste the invite link or code your friend shared."
        }
    }

    var placeholder: String {
        switch self {
        case .username: "@username"
        case .inviteLink: "\(FriendInviteLink.webHost)/invite/…"
        }
    }

    var actionTitle: String {
        switch self {
        case .username: "Send request"
        case .inviteLink: "Join their circle"
        }
    }

    var actionSystemImage: String {
        switch self {
        case .username: "paperplane"
        case .inviteLink: "link"
        }
    }

    func validationMessage(for input: String) -> String? {
        do {
            switch self {
            case .username:
                _ = try Username.normalize(input)
            case .inviteLink:
                _ = try FriendInviteLink.parse(input)
            }
            return nil
        } catch {
            return error.localizedDescription
        }
    }
}
