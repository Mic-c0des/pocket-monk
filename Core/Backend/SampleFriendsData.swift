import Foundation

enum SampleFriendsData {
    static let guest = FriendProfile(
        id: sampleID(0),
        username: "guest",
        displayName: "You",
        monkName: "Milo"
    )
    static let sage = FriendProfile(
        id: sampleID(1),
        username: "sage",
        displayName: "Sage Rivera",
        monkName: "Pebble"
    )
    static let juniper = FriendProfile(
        id: sampleID(2),
        username: "juniper",
        displayName: "Juniper Hale",
        monkName: "Fern"
    )
    static let river = FriendProfile(
        id: sampleID(3),
        username: "river",
        displayName: "River Okafor",
        monkName: "Drift"
    )
    static let kai = FriendProfile(
        id: sampleID(4),
        username: "kai.lee",
        displayName: "Kai Lee",
        monkName: "Ember"
    )
    static let noor = FriendProfile(
        id: sampleID(5),
        username: "noor",
        displayName: "Noor Haddad",
        monkName: "Lotus"
    )

    static let directory = [sage, juniper, river, kai, noor]

    static let tryItHint =
        "This build uses sample friends. Try the username noor, or the invite code RIVER123. The code KAILEE01 has expired."

    static func initialFriendships(relativeTo date: Date) -> [Friendship] {
        [
            Friendship(profile: sage, status: .accepted, updatedAt: date.addingTimeInterval(-3 * 86_400)),
            Friendship(profile: juniper, status: .incoming, updatedAt: date.addingTimeInterval(-3_600)),
        ]
    }

    static func invites(relativeTo date: Date) -> [FriendInvite] {
        [
            ("RIVER123", river, date.addingTimeInterval(7 * 86_400)),
            ("KAILEE01", kai, date.addingTimeInterval(-86_400)),
        ]
        .compactMap { code, inviter, expiresAt in
            (try? FriendInviteCode(code)).map {
                FriendInvite(code: $0, inviter: inviter, expiresAt: expiresAt)
            }
        }
    }

    // Stable IDs so saved friendships still match the directory after relaunch.
    private static func sampleID(_ index: UInt8) -> UUID {
        UUID(uuid: (0x5A, 0x4D, 0, 0, 0, 0, 0x40, 0, 0x80, 0, 0, 0, 0, 0, 0, index))
    }
}
