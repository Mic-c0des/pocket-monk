import Testing
@testable import Pocket_Monk

@MainActor
struct UsernameTests {
    @Test func normalizesHandleWhitespaceAndCase() throws {
        #expect(try Username.normalize("  @Sage.Rivera ") == "sage.rivera")
    }

    @Test func rejectsEmptyInput() {
        #expect(throws: UsernameError.empty) {
            try Username.normalize("  @ ")
        }
    }

    @Test func rejectsShortUsername() {
        #expect(throws: UsernameError.tooShort) {
            try Username.normalize("ab")
        }
    }

    @Test func rejectsLongUsername() {
        #expect(throws: UsernameError.tooLong) {
            try Username.normalize(String(repeating: "a", count: Username.maximumLength + 1))
        }
    }

    @Test(arguments: ["sage rivera", "sage!", "sāge"])
    func rejectsInvalidCharacters(input: String) {
        #expect(throws: UsernameError.invalidCharacters) {
            try Username.normalize(input)
        }
    }

    @Test func addFriendMethodReportsValidationMessages() {
        #expect(AddFriendMethod.username.validationMessage(for: "noor") == nil)
        #expect(AddFriendMethod.username.validationMessage(for: "ab") != nil)
        #expect(AddFriendMethod.inviteLink.validationMessage(for: "RIVER123") == nil)
        #expect(AddFriendMethod.inviteLink.validationMessage(for: "https://example.com") != nil)
    }
}
