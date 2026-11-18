import SwiftUI

struct DuelDetailView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: DuelsViewModel

    let duelID: UUID

    private var duel: Duel? {
        viewModel.book?.duel(with: duelID)
    }

    var body: some View {
        Group {
            if let duel {
                ScrollView {
                    // Ticks every second for the countdown; the duel finishes on screen when time runs out.
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        DuelDetailContent(viewModel: viewModel, duel: duel, date: context.date)
                    }
                    .padding(PocketMonkSpacing.large)
                    .frame(maxWidth: 640, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .top)
                }
                .refreshable {
                    await viewModel.loadScoreboard(for: duel)
                }
            } else if viewModel.book == nil {
                ProgressView("Gathering your duel…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                PocketMonkMessageView(
                    title: "This duel is no longer available",
                    detail: "It may have been declined or cancelled.",
                    systemImage: "figure.martial.arts"
                ) {
                    EmptyView()
                }
            }
        }
        .background(PocketMonkColors.canvas.color(for: colorScheme))
        .navigationTitle(duel.map { "vs \($0.rival.displayName)" } ?? "Duel")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: duel?.startedAt) {
            // Normally the list has loaded already; previews and deep links start here.
            if viewModel.book == nil {
                await viewModel.load()
            }
            guard let duel else { return }
            await viewModel.loadScoreboard(for: duel)
        }
    }
}

private struct DuelDetailContent: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: DuelsViewModel

    let duel: Duel
    let date: Date

    private var status: DuelStatus {
        duel.status(at: date)
    }

    private var rivalFirstName: String {
        duel.rival.displayName.split(separator: " ").first.map(String.init) ?? duel.rival.displayName
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PocketMonkSpacing.large) {
            header
            timerCard
            if status != .pending {
                scoreboardCard
            }
            stakeCard
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: PocketMonkSpacing.small) {
            PocketMonkStatusPill(title: status.title, color: status.colorToken)
            Text("\(viewModel.currentUser.displayName) vs \(duel.rival.displayName)")
                .font(.largeTitle.bold())
            Text("\(viewModel.currentUser.monkName) vs \(duel.rival.monkName)")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: Timer

    @ViewBuilder
    private var timerCard: some View {
        PocketMonkCard {
            VStack(alignment: .leading, spacing: PocketMonkSpacing.medium) {
                switch status {
                case .pending:
                    pendingTimer
                case .active:
                    activeTimer
                case .finished:
                    finishedTimer
                }
            }
        }
    }

    @ViewBuilder
    private var pendingTimer: some View {
        PocketMonkSectionLabel(title: duel.isIncoming ? "New challenge" : "Waiting")
        Text(duel.isIncoming ? "\(rivalFirstName) challenged you" : "Waiting for \(rivalFirstName)")
            .font(.title2.bold())
        Text(
            duel.isIncoming
                ? "Accept to start the \(duel.duration.title) timer."
                : "The \(duel.duration.title) timer starts when \(rivalFirstName) accepts."
        )
        .font(.body)
        .foregroundStyle(.secondary)

        if duel.isIncoming {
            HStack(spacing: PocketMonkSpacing.medium) {
                Button("Decline", systemImage: "xmark") {
                    Task {
                        await viewModel.declineDuel(duel.id)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button("Accept", systemImage: "checkmark") {
                    Task {
                        await viewModel.acceptDuel(duel.id)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(PocketMonkColors.plum.color(for: colorScheme))
            }
            .disabled(viewModel.isProcessing(duel.id))
        } else {
            Button("Cancel challenge", systemImage: "xmark", role: .destructive) {
                Task {
                    await viewModel.cancelDuel(duel.id)
                }
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isProcessing(duel.id))
        }
    }

    @ViewBuilder
    private var activeTimer: some View {
        let remaining = duel.timeRemaining(at: date) ?? 0

        PocketMonkSectionLabel(title: "Time left")
        Text(DuelCountdownFormatter.compact(remaining))
            .font(.system(size: 48, weight: .bold, design: .rounded))
            .monospacedDigit()
            .contentTransition(.numericText(countsDown: true))
            .accessibilityLabel(DuelCountdownFormatter.spoken(remaining))

        ProgressView(value: duel.elapsedFraction(at: date))
            .tint(PocketMonkColors.plum.color(for: colorScheme))
            .accessibilityLabel("Duel progress")
            .accessibilityValue("\(Int((duel.elapsedFraction(at: date) * 100).rounded())) percent complete")

        if let endsAt = duel.endsAt {
            Text("Ends \(endsAt.formatted(.dateTime.weekday(.wide).hour().minute()))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var finishedTimer: some View {
        PocketMonkSectionLabel(title: "Duel complete")
        Text(DuelCountdownFormatter.expiredText)
            .font(.title2.bold())
        if let endsAt = duel.endsAt {
            Text("Ended \(endsAt.formatted(date: .abbreviated, time: .shortened)).")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        Text("The final result and a shareable card are on the way.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    // MARK: Monk vs monk

    private var scoreboardCard: some View {
        PocketMonkCard {
            VStack(alignment: .leading, spacing: PocketMonkSpacing.medium) {
                PocketMonkSectionLabel(title: status == .active ? "Live standing" : "Final standing")

                switch viewModel.scoreboard(for: duel.id) {
                case nil, .loading?:
                    ProgressView("Checking on both monks…")
                        .frame(maxWidth: .infinity)
                case let .failed(message)?:
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Try again", systemImage: "arrow.clockwise") {
                        Task {
                            await viewModel.loadScoreboard(for: duel)
                        }
                    }
                    .buttonStyle(.bordered)
                case let .loaded(scoreboard)?:
                    scoreboardContent(scoreboard)
                }
            }
        }
    }

    @ViewBuilder
    private func scoreboardContent(_ scoreboard: DuelScoreboard) -> some View {
        HStack(alignment: .top, spacing: PocketMonkSpacing.medium) {
            DuelMonkColumn(standing: scoreboard.me, isLeading: status == .active && scoreboard.leader == .me)
            Text("vs")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.top, 40)
                .accessibilityHidden(true)
            DuelMonkColumn(standing: scoreboard.rival, isLeading: status == .active && scoreboard.leader == .rival)
        }

        if status == .active {
            Text(leaderMessage(scoreboard.leader))
                .font(.headline)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
        }

        Text("Scores compare each side’s daily average during the duel with their own baseline. At baseline a monk scores 50.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func leaderMessage(_ leader: DuelLeader) -> String {
        switch leader {
        case .me: "You’re ahead right now"
        case .rival: "\(rivalFirstName) is ahead right now"
        case .tied: "Neck and neck"
        }
    }

    // MARK: Stake

    private var stakeCard: some View {
        PocketMonkCard {
            VStack(alignment: .leading, spacing: PocketMonkSpacing.small) {
                PocketMonkSectionLabel(title: "Stake")
                PocketMonkListRow(
                    title: duel.stake.title,
                    detail: "\(duel.duration.title) duel · \(duel.isIncoming ? "\(rivalFirstName) challenged you" : "You sent the challenge")",
                    systemImage: duel.stake.systemImage
                )
            }
        }
    }
}

private struct DuelMonkColumn: View {
    @Environment(\.colorScheme) private var colorScheme

    let standing: DuelStanding
    let isLeading: Bool

    var body: some View {
        VStack(spacing: PocketMonkSpacing.small) {
            MonkIllustration(
                accessibilityLabel: "\(standing.monkName), \(standing.mood.title.lowercased()) monk"
            )
            .frame(width: 88, height: 88)

            VStack(spacing: PocketMonkSpacing.extraSmall) {
                Text(standing.name)
                    .font(.headline)
                Text("\(standing.monkName) the monk")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)

            PocketMonkStatusPill(title: standing.mood.title, color: standing.mood.colorToken)

            Text("\(standing.zenScore)")
                .font(.title.bold())
                .monospacedDigit()
                .accessibilityLabel("Zen score \(standing.zenScore) out of 100")

            Text(standing.baselineComparison)
                .font(.caption)
                .foregroundStyle(
                    standing.changeFromBaselinePercent <= 0
                        ? PocketMonkColors.jade.color(for: colorScheme)
                        : PocketMonkColors.ember.color(for: colorScheme)
                )
                .multilineTextAlignment(.center)

            if isLeading {
                Label("Ahead", systemImage: "crown")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PocketMonkColors.plum.color(for: colorScheme))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("Active duel") {
    let now = Date.now
    let duel = Duel(
        rival: SampleFriendsData.sage,
        initiator: .me,
        duration: .oneWeek,
        stake: .coffee,
        createdAt: now.addingTimeInterval(-3 * 86_400),
        startedAt: now.addingTimeInterval(-2 * 86_400)
    )
    return NavigationStack {
        DuelDetailView(viewModel: .preview(duels: [duel]), duelID: duel.id)
    }
}

#Preview("Ending in 15 seconds") {
    let now = Date.now
    let duel = Duel(
        rival: SampleFriendsData.sage,
        initiator: .rival,
        duration: .oneDay,
        stake: .phoneFreeWalk,
        createdAt: now.addingTimeInterval(-86_400),
        startedAt: now.addingTimeInterval(-86_400 + 15)
    )
    return NavigationStack {
        DuelDetailView(viewModel: .preview(duels: [duel]), duelID: duel.id)
    }
}

#Preview("Incoming challenge") {
    NavigationStack {
        DuelDetailView(viewModel: .preview(), duelID: SampleDuelsData.incomingChallengeID)
    }
}
