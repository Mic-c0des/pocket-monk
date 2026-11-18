import Foundation

struct DailyScreenTime: Codable, Equatable, Identifiable, Sendable {
    let date: Date
    let minutes: Int

    var id: Date { date }
}
