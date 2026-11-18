import Foundation

struct Monk: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}
