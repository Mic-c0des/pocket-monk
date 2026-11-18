import Foundation

/// What the duel is played for. Stakes are friendly promises; the app never handles money.
enum DuelStake: Codable, Hashable, Sendable {
    case braggingRights
    case coffee
    case phoneFreeWalk
    case custom(String)

    static let maximumCustomLength = 60

    /// Trims the text and checks it fits; use this rather than building `.custom` directly from input.
    static func makeCustom(_ input: String) throws -> DuelStake {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            throw DuelError.emptyStake
        }
        guard text.count <= maximumCustomLength else {
            throw DuelError.stakeTooLong
        }
        return .custom(text)
    }

    var title: String {
        switch self {
        case .braggingRights: "Bragging rights"
        case .coffee: "Loser buys coffee"
        case .phoneFreeWalk: "Loser plans a phone-free walk"
        case let .custom(text): text
        }
    }

    var systemImage: String {
        switch self {
        case .braggingRights: "trophy"
        case .coffee: "cup.and.saucer"
        case .phoneFreeWalk: "figure.walk"
        case .custom: "pencil"
        }
    }
}
