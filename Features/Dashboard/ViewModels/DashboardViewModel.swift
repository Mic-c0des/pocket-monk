import Combine
import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published private(set) var state: DashboardViewState = .loading

    private let dataProvider: any DashboardDataProviding
    private let scoreCalculator: ZenScoreCalculator
    private let analytics: any AnalyticsTracking

    init(
        dataProvider: any DashboardDataProviding = SampleDashboardDataService(),
        scoreCalculator: ZenScoreCalculator = ZenScoreCalculator(),
        analytics: any AnalyticsTracking = LocalAnalyticsTracker()
    ) {
        self.dataProvider = dataProvider
        self.scoreCalculator = scoreCalculator
        self.analytics = analytics
    }

    func loadDashboard() async {
        state = .loading

        do {
            try Task.checkCancellation()
            guard let data = try await dataProvider.loadDashboardData() else {
                state = .empty
                return
            }
            try Task.checkCancellation()

            guard data.recentDays.allSatisfy({ $0.minutes >= 0 }) else {
                throw ZenScoreError.negativeScreenTime
            }

            let score = try scoreCalculator.calculate(
                screenTimeMinutes: data.todayScreenTimeMinutes,
                baselineMinutes: data.baselineAverageMinutes
            )
            state = .loaded(
                DashboardSnapshot(
                    monk: data.monk,
                    mood: MonkMood.from(zenScore: score),
                    zenScore: score,
                    todayScreenTimeMinutes: data.todayScreenTimeMinutes,
                    baselineAverageMinutes: data.baselineAverageMinutes,
                    recentDays: data.recentDays,
                    isStale: DashboardFreshness.isStale(
                        lastUpdatedAt: data.lastUpdatedAt,
                        now: .now
                    )
                )
            )
        } catch is CancellationError {
            return
        } catch {
            analytics.track(.dashboardLoadFailed)
            state = .failed(error.localizedDescription)
        }
    }
}
