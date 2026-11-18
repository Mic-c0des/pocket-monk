import Foundation
import Testing
@testable import Pocket_Monk

@MainActor
struct FriendInviteLinkTests {
    @Test(arguments: [
        "https://pocketmonk.app/invite/RIVER123",
        "https://pocketmonk.app/invite/river123/",
        "pocketmonk.app/invite/RIVER123",
        "pocketmonk://invite/RIVER123",
        " river123 ",
    ])
    func parsesSupportedFormats(input: String) throws {
        let expected = try FriendInviteCode("RIVER123")
        #expect(try FriendInviteLink.parse(input) == expected)
    }

    @Test func generatedLinkParsesBackToItsCode() throws {
        let code = FriendInviteCode.random()
        let url = try #require(FriendInviteLink.url(for: code))
        #expect(try FriendInviteLink.parse(url.absoluteString) == code)
    }

    @Test(arguments: [
        "https://example.com/invite/RIVER123",
        "https://pocketmonk.app/profile/RIVER123",
        "https://pocketmonk.app/invite",
        "pocketmonk://profile/RIVER123",
        "ftp://pocketmonk.app/invite/RIVER123",
    ])
    func rejectsUnrecognizedLinks(input: String) {
        #expect(throws: FriendInviteError.unrecognizedLink) {
            try FriendInviteLink.parse(input)
        }
    }

    @Test(arguments: ["SHORT", "TOOLONGCODE", "https://pocketmonk.app/invite/RIVER-12"])
    func rejectsMalformedCodes(input: String) {
        #expect(throws: FriendInviteError.invalidCode) {
            try FriendInviteLink.parse(input)
        }
    }

    @Test func rejectsEmptyInput() {
        #expect(throws: FriendInviteError.empty) {
            try FriendInviteLink.parse("   ")
        }
    }

    @Test func inviteExpiresAtItsExpiryDate() throws {
        let expiry = Date(timeIntervalSince1970: 1_800_000_000)
        let invite = FriendInvite(
            code: try FriendInviteCode("RIVER123"),
            inviter: SampleFriendsData.river,
            expiresAt: expiry
        )

        #expect(!invite.isExpired(at: expiry.addingTimeInterval(-1)))
        #expect(invite.isExpired(at: expiry))
    }
}
