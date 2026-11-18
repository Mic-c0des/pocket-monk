import Foundation

struct FriendProfile: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let username: String
    let displayName: String
    let monkName: String

    init(id: UUID = UUID(), username: String, displayName: String, monkName: String) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.monkName = monkName
    }
}
