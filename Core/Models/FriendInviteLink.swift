import Foundation

enum FriendInviteLink {
    static let scheme = "pocketmonk"
    // Placeholder until the production domain is chosen with the backend.
    static let webHost = "pocketmonk.app"

    static func url(for code: FriendInviteCode) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = webHost
        components.path = "/invite/\(code.rawValue)"
        return components.url
    }

    /// Accepts a web link, a `pocketmonk://invite/CODE` link, or a bare code.
    static func parse(_ input: String) throws -> FriendInviteCode {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw FriendInviteError.empty
        }
        if !trimmed.contains("/") && !trimmed.contains(":") {
            return try FriendInviteCode(trimmed)
        }

        let candidate = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
        guard let url = URL(string: candidate),
              let scheme = url.scheme?.lowercased(),
              let host = url.host()?.lowercased()
        else {
            throw FriendInviteError.unrecognizedLink
        }
        let path = url.pathComponents.filter { $0 != "/" }

        switch (scheme, host) {
        case (Self.scheme, "invite") where path.count == 1:
            return try FriendInviteCode(path[0])
        case ("https", Self.webHost) where path.count == 2 && path[0] == "invite":
            return try FriendInviteCode(path[1])
        default:
            throw FriendInviteError.unrecognizedLink
        }
    }
}
