import Charts
import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel

    init(viewModel: DashboardViewModel? = nil) {
        _viewModel = StateObject(
            wrappedValue: viewModel ?? DashboardViewModel()
        )
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                DashboardLoadingView()
            case .empty:
                DashboardEmptyView(retry: loadDashboard)
            case let .loaded(snapshot):
                DashboardContentView(snapshot: snapshot)
            case let .failed(message):
                DashboardErrorView(message: message, retry: loadDashboard)
            }
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadDashboard()
        }
    }

    private func loadDashboard() {
        Task {
            await viewModel.loadDashboard()
        }
    }
}

private struct DashboardContentView: View {
    @Environment(\.colorScheme) private var colorScheme

    let snapshot: DashboardSnapshot

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: PocketMonkSpacing.large) {
                greeting
                if snapshot.isStale {
                    Label(
                        "Screen-time data may be out of date",
                        systemImage: "clock.arrow.circlepath"
                    )
                    .font(.subheadline)
                    .foregroundStyle(PocketMonkColors.ember.color(for: colorScheme))
                }
                MonkMoodCard(snapshot: snapshot)
                LiveActivityCard(snapshot: snapshot)
                DailySummaryCard(snapshot: snapshot)
                ScreenTimeTrendCard(snapshot: snapshot)
            }
            .padding(PocketMonkSpacing.large)
            .frame(maxWidth: 640, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .background(PocketMonkColors.canvas.color(for: colorScheme))
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: PocketMonkSpacing.small) {
            Text("Your practice")
                .font(.largeTitle.bold())
            Text("A little more calm, one day at a time.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
}

private struct MonkMoodCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let snapshot: DashboardSnapshot

    private var moodColor: AdaptiveColorToken {
        snapshot.mood.colorToken
    }

    var body: some View {
        PocketMonkCard {
            VStack(alignment: .leading, spacing: PocketMonkSpacing.medium) {
                PocketMonkStatusPill(title: snapshot.mood.title, color: moodColor)

                HStack(alignment: .top, spacing: PocketMonkSpacing.medium) {
                    MonkIllustration(
                        accessibilityLabel: "\(snapshot.monk.name), \(snapshot.mood.title.lowercased()) monk meditating"
                    )
                    .frame(width: 120, height: 120)

                    VStack(alignment: .leading, spacing: PocketMonkSpacing.small) {
                        Text(snapshot.monk.name)
                            .font(.title2.bold())
                        Text(snapshot.mood.message)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: PocketMonkSpacing.small) {
                    HStack {
                        Text("Zen score")
                        Spacer()
                        Text("\(snapshot.zenScore) / 100")
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)

                    ProgressView(value: Double(snapshot.zenScore), total: 100)
                        .tint(moodColor.color(for: colorScheme))
                        .accessibilityLabel("Zen score")
                        .accessibilityValue("\(snapshot.zenScore) out of 100")

                    Text("At your baseline, your score is 50; at half, it’s 75.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct DailySummaryCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let snapshot: DashboardSnapshot

    var body: some View {
        PocketMonkCard {
            VStack(alignment: .leading, spacing: PocketMonkSpacing.medium) {
                PocketMonkSectionLabel(title: "Today's summary")

                HStack(alignment: .firstTextBaseline, spacing: PocketMonkSpacing.small) {
                    Text(durationLabel(snapshot.todayScreenTimeMinutes))
                        .font(.largeTitle.bold())
                    Text("screen time")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text(snapshot.baselineComparisonMessage)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(
                        snapshot.differenceFromBaselineMinutes <= 0
                            ? PocketMonkColors.jade.color(for: colorScheme)
                            : PocketMonkColors.ember.color(for: colorScheme)
                    )

                Text("Daily baseline: \(durationLabel(snapshot.baselineAverageMinutes))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func durationLabel(_ minutes: Int) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        guard hours > 0 else { return "\(minutes) min" }
        guard remainingMinutes > 0 else { return "\(hours) hr" }
        return "\(hours) hr \(remainingMinutes) min"
    }
}

private struct ScreenTimeTrendCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let snapshot: DashboardSnapshot

    var body: some View {
        PocketMonkCard {
            VStack(alignment: .leading, spacing: PocketMonkSpacing.medium) {
                PocketMonkSectionLabel(title: "Recent screen time")
                Text("Compared with your daily baseline")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if snapshot.recentDays.isEmpty {
                    Text("A trend will appear when more days are available.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                } else {
                    trendChart
                }
            }
        }
    }

    private var trendChart: some View {
        Chart {
            ForEach(snapshot.recentDays) { day in
                BarMark(
                    x: .value("Day", day.date, unit: .day),
                    y: .value("Screen time", day.minutes)
                )
                .foregroundStyle(
                    day.minutes <= snapshot.baselineAverageMinutes
                        ? PocketMonkColors.jade.color(for: colorScheme)
                        : PocketMonkColors.ember.color(for: colorScheme)
                )
            }

            RuleMark(y: .value("Baseline", snapshot.baselineAverageMinutes))
                .foregroundStyle(PocketMonkColors.stone.color(for: colorScheme))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
        }
        .chartYAxisLabel("Minutes per day")
        .frame(height: 180)
        .accessibilityLabel("Screen time trend for the last seven days")
    }
}

private struct DashboardLoadingView: View {
    var body: some View {
        ProgressView("Preparing your daily summary…")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityLabel("Loading your screen-time summary")
    }
}

private struct DashboardEmptyView: View {
    let retry: () -> Void

    var body: some View {
        PocketMonkMessageView(
            title: "No screen-time summary yet",
            detail: "Your daily zen summary will appear when screen-time data is available.",
            systemImage: "hourglass"
        ) {
            Button("Try again", systemImage: "arrow.clockwise", action: retry)
                .buttonStyle(.bordered)
        }
    }
}

private struct DashboardErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        PocketMonkMessageView(
            title: "We couldn’t load your summary",
            detail: message,
            systemImage: "exclamationmark.triangle"
        ) {
            Button("Try again", systemImage: "arrow.clockwise", action: retry)
                .buttonStyle(.bordered)
        }
    }
}

#Preview("Dashboard") {
    NavigationStack {
        DashboardView()
    }
}
