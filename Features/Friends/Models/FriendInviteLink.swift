import Foundation

nonisolated struct FriendInvite: Equatable, Sendable {
    let username: String
    let token: UUID
    let expiresAt: Date
}

nonisolated enum FriendInviteLink {
    static let scheme = "pocketmonk"
    static let lifetime: TimeInterval = 7 * 24 * 60 * 60

    static func make(username: String, now: Date) throws -> URL {
        guard let normalizedUsername = FriendUsername.normalize(username) else {
            throw FriendServiceError.invalidInviteLink
        }

        var components = URLComponents()
        components.scheme = scheme
        components.host = "invite"
        components.queryItems = [
            URLQueryItem(name: "username", value: normalizedUsername),
            URLQueryItem(name: "token", value: UUID().uuidString),
            URLQueryItem(
                name: "expires",
                value: String(Int(now.addingTimeInterval(lifetime).timeIntervalSince1970))
            )
        ]
        guard let url = components.url else {
            throw FriendServiceError.invalidInviteLink
        }
        return url
    }

    static func parse(_ url: URL, now: Date) throws -> FriendInvite {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme?.lowercased() == scheme,
              components.host?.lowercased() == "invite",
              components.path.isEmpty,
              let queryItems = components.queryItems,
              queryItems.count == 3,
              let usernameValue = value(named: "username", in: queryItems),
              let tokenValue = value(named: "token", in: queryItems),
              let expirationValue = value(named: "expires", in: queryItems),
              let username = FriendUsername.normalize(usernameValue),
              let token = UUID(uuidString: tokenValue),
              let expirationTimestamp = TimeInterval(expirationValue)
        else {
            throw FriendServiceError.invalidInviteLink
        }

        let expiresAt = Date(timeIntervalSince1970: expirationTimestamp)
        guard expiresAt > now else {
            throw FriendServiceError.expiredInviteLink
        }

        return FriendInvite(
            username: username,
            token: token,
            expiresAt: expiresAt
        )
    }

    private static func value(named name: String, in queryItems: [URLQueryItem]) -> String? {
        let matches = queryItems.filter { $0.name == name }
        guard matches.count == 1 else { return nil }
        return matches[0].value
    }
}
