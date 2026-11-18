import Foundation

struct SampleDashboardDataService: DashboardDataProviding {
    func loadDashboardData() async throws -> DashboardData? {
        let minutesByDay = [190, 210, 180, 175, 160, 145, 120]
        let today = Calendar.current.startOfDay(for: .now)
        let recentDays = try minutesByDay.enumerated().map { index, minutes in
            let dayOffset = index - minutesByDay.count + 1
            guard let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: today) else {
                throw SampleDashboardDataError.unavailable
            }
            return DailyScreenTime(date: date, minutes: minutes)
        }

        return DashboardData(
            monk: Monk(name: "Milo"),
            todayScreenTimeMinutes: minutesByDay[minutesByDay.count - 1],
            baselineAverageMinutes: 240,
            recentDays: recentDays,
            lastUpdatedAt: .now
        )
    }
}

private enum SampleDashboardDataError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        "Sample screen-time history is unavailable."
    }
}
