import Foundation

enum Username {
    static let minimumLength = 3
    static let maximumLength = 20

    private static let allowedCharacters = CharacterSet(
        charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789_."
    )

    /// Accepts "@Name" or "name" and returns the lowercase handle used for lookups.
    static func normalize(_ input: String) throws -> String {
        var username = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if username.hasPrefix("@") {
            username.removeFirst()
        }
        username = username.lowercased()

        guard !username.isEmpty else {
            throw UsernameError.empty
        }
        guard username.count >= minimumLength else {
            throw UsernameError.tooShort
        }
        guard username.count <= maximumLength else {
            throw UsernameError.tooLong
        }
        guard username.unicodeScalars.allSatisfy(allowedCharacters.contains) else {
            throw UsernameError.invalidCharacters
        }
        return username
    }
}

enum UsernameError: LocalizedError, Equatable, Sendable {
    case empty
    case tooShort
    case tooLong
    case invalidCharacters

    var errorDescription: String? {
        switch self {
        case .empty:
            "Enter a username."
        case .tooShort:
            "Usernames have at least \(Username.minimumLength) characters."
        case .tooLong:
            "Usernames have at most \(Username.maximumLength) characters."
        case .invalidCharacters:
            "Usernames use only letters, numbers, periods, and underscores."
        }
    }
}
