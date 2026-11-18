import ActivityKit
import Foundation

nonisolated public struct MonkActivityAttributes: ActivityAttributes, Sendable {
    nonisolated public struct ContentState: Codable, Hashable, Sendable {
        public let mood: String
        public let zenScore: Int
        public let updatedAt: Date

        public init(mood: String, zenScore: Int, updatedAt: Date) {
            self.mood = mood
            self.zenScore = zenScore
            self.updatedAt = updatedAt
        }
    }

    public let monkName: String

    public init(monkName: String) {
        self.monkName = monkName
    }
}
