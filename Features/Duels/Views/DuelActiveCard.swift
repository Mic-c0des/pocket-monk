import SwiftUI

struct DuelActiveCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let duel: DuelRecord
    let dashboardSnapshot: DashboardSnapshot?
    let didExpire: () -> Void

    var body: some View {
        PocketMonkCard {
            VStack(alignment: .leading, spacing: PocketMonkSpacing.medium) {
                duelHeader
                monkComparison
                baselineDetail
                countdown
                Label(
                    DuelStake.title(for: duel.stakePoints) ?? "Unknown stake",
                    systemImage: "sparkles"
                )
                .font(.subheadline.weight(.medium))
                .foregroundStyle(PocketMonkColors.plum.color(for: colorScheme))
            }
        }
    }

    private var duelHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: PocketMonkSpacing.extraSmall) {
                Text("You vs. @\(duel.opponentUsername)")
                    .font(.headline)
                Text(
                    DuelRules.durationLabel(
                        for: duel.duration,
                        seconds: duel.durationSeconds
                    )
                )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            PocketMonkStatusPill(
                title: duel.status.title,
                color: PocketMonkColors.jade
            )
        }
    }

    private var monkComparison: some View {
        HStack(alignment: .top, spacing: PocketMonkSpacing.medium) {
            participant(
                title: "Your monk",
                subtitle: dashboardSnapshot?.mood.title ?? "Score unavailable",
                score: dashboardSnapshot.map { "\($0.zenScore)" } ?? "—",
                accessibilityLabel: "Your monk"
            )

            Text("VS")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .padding(.top, PocketMonkSpacing.extraLarge)

            participant(
                title: "@\(duel.opponentUsername)",
                subtitle: "Simulated score",
                score: duel.opponentZenScoreAtStart.map(String.init) ?? "—",
                accessibilityLabel: "Demo monk for \(duel.opponentUsername)"
            )
        }
    }

    private var baselineDetail: some View {
        VStack(alignment: .leading, spacing: PocketMonkSpacing.extraSmall) {
            if let dashboardSnapshot {
                Text(dashboardSnapshot.baselineComparisonMessage)
                    .font(.subheadline.weight(.medium))
                Text("Your score is normalized against your daily baseline. The opponent score is simulated.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Your zen score is currently unavailable.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var countdown: some View {
        Group {
            if let endsAt = duel.endsAt {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let hasExpired = context.date >= endsAt
                    HStack {
                        Label(
                            hasExpired ? "Time complete" : "Time remaining",
                            systemImage: "hourglass"
                        )
                        Spacer()
                        Text(DuelRules.countdown(endsAt: endsAt, now: context.date))
                            .font(.headline.monospacedDigit())
                            .contentTransition(.numericText())
                    }
                    .onChange(of: hasExpired) { _, expired in
                        if expired {
                            didExpire()
                        }
                    }
                }
            } else {
                Label(
                    "This active duel has no end time.",
                    systemImage: "exclamationmark.triangle"
                )
                .font(.subheadline)
                .foregroundStyle(PocketMonkColors.ember.color(for: colorScheme))
            }
        }
    }

    private func participant(
        title: String,
        subtitle: String,
        score: String,
        accessibilityLabel: String
    ) -> some View {
        VStack(spacing: PocketMonkSpacing.small) {
            MonkIllustration(accessibilityLabel: accessibilityLabel)
                .frame(width: 88, height: 88)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text("\(score) / 100")
                .font(.title3.bold().monospacedDigit())
                .accessibilityLabel("\(title) zen score")
                .accessibilityValue("\(score) out of 100")
        }
        .frame(maxWidth: .infinity)
    }
}
