import Foundation

struct FriendInviteCode: Codable, Hashable, Sendable {
    static let length = 8

    private static let generatorAlphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")

    let rawValue: String

    init(_ rawValue: String) throws {
        let code = rawValue.uppercased()
        guard code.count == Self.length,
              code.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber) })
        else {
            throw FriendInviteError.invalidCode
        }
        self.rawValue = code
    }

    private init(generated rawValue: String) {
        self.rawValue = rawValue
    }

    static func random() -> FriendInviteCode {
        // Skips look-alike characters (0/O, 1/I) so codes are easy to read aloud.
        let characters = (0..<length).map { _ in generatorAlphabet.randomElement() ?? "A" }
        return FriendInviteCode(generated: String(characters))
    }
}

struct FriendInvite: Equatable, Sendable {
    let code: FriendInviteCode
    let inviter: FriendProfile
    let expiresAt: Date

    func isExpired(at date: Date) -> Bool {
        date >= expiresAt
    }
}

enum FriendInviteError: LocalizedError, Equatable, Sendable {
    case empty
    case unrecognizedLink
    case invalidCode
    case notFound
    case expired
    case ownInvite
    case linkUnavailable

    var errorDescription: String? {
        switch self {
        case .empty:
            "Paste an invite link or code."
        case .unrecognizedLink:
            "That doesn’t look like a Pocket Monk invite link."
        case .invalidCode:
            "Invite codes have \(FriendInviteCode.length) letters and numbers."
        case .notFound:
            "We couldn’t find that invite. Ask your friend for a new link."
        case .expired:
            "This invite has expired. Ask your friend for a new link."
        case .ownInvite:
            "That’s your own invite link. Share it with a friend instead."
        case .linkUnavailable:
            "Your invite link isn’t available right now."
        }
    }
}
