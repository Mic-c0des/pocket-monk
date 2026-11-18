import SwiftData
import SwiftUI

struct DuelsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel: DuelViewModel
    @StateObject private var dashboardViewModel: DashboardViewModel
    @State private var presentation: DuelsPresentation?
    @State private var resolvingDuelID: UUID?

    private let onFindFriends: () -> Void

    init(
        viewModel: DuelViewModel? = nil,
        dashboardViewModel: DashboardViewModel? = nil,
        onFindFriends: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(
            wrappedValue: viewModel ?? DuelViewModel()
        )
        _dashboardViewModel = StateObject(
            wrappedValue: dashboardViewModel ?? DashboardViewModel()
        )
        self.onFindFriends = onFindFriends
    }

    var body: some View {
        Group {
            if !viewModel.hasLoaded {
                ProgressView("Loading your duels…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityLabel("Loading duels")
            } else if let message = viewModel.loadErrorMessage {
                VStack(spacing: PocketMonkSpacing.medium) {
                    Label("We couldn’t load your duels.", systemImage: "exclamationmark.triangle")
                        .font(.headline)
                        .foregroundStyle(PocketMonkColors.ember.color(for: colorScheme))
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Try again", systemImage: "arrow.clockwise") {
                        viewModel.refresh()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(PocketMonkSpacing.large)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: PocketMonkSpacing.large) {
                        introduction
                        demoNotice
                        pointBalance
                        feedbackMessage
                        if viewModel.friends.isEmpty {
                            emptyFriendsCard
                        } else {
                            createChallengeButton
                        }
                        pendingSection
                        activeSection
                        pastChallengesSection
                    }
                    .padding(PocketMonkSpacing.large)
                    .frame(maxWidth: 640, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .top)
                }
            }
        }
        .background(PocketMonkColors.canvas.color(for: colorScheme))
        .navigationTitle("Duels")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            viewModel.load(using: modelContext)
            await dashboardViewModel.loadDashboard()
        }
        .sheet(item: $presentation) { presentation in
            switch presentation {
            case .challenge:
                NavigationStack {
                    DuelChallengeFlowView(
                        friends: viewModel.friends,
                        availablePoints: viewModel.pointBalance ?? 0
                    ) {
                        opponentUsername,
                        duration,
                        customEndDate,
                        stakePoints in
                        guard viewModel.createDuel(
                            opponentUsername: opponentUsername,
                            duration: duration,
                            customEndDate: customEndDate,
                            stakePoints: stakePoints
                        ) else {
                            return viewModel.errorMessage ?? "The challenge couldn’t be created."
                        }
                        return nil
                    }
                }
                .presentationDetents([.large])
            case let .result(duel):
                DuelResultView(duel: duel, pointBalance: viewModel.pointBalance)
                    .presentationDetents([.large])
            }
        }
    }

    private var dashboardSnapshot: DashboardSnapshot? {
        guard case let .loaded(snapshot) = dashboardViewModel.state else {
            return nil
        }
        return snapshot
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: PocketMonkSpacing.small) {
            Text("Friendly challenges")
                .font(.largeTitle.bold())
            Text("Choose a friend, set your practice window, and find your balance together.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var demoNotice: some View {
        Label(
            "Local demo — responses and scores are simulated.",
            systemImage: "iphone"
        )
        .font(.subheadline)
        .foregroundStyle(PocketMonkColors.plum.color(for: colorScheme))
    }

    @ViewBuilder
    private var pointBalance: some View {
        if let pointBalance = viewModel.pointBalance {
            Label(
                "Your demo balance: \(pointBalance) virtual points",
                systemImage: "sparkles"
            )
            .font(.subheadline.weight(.medium))
            .foregroundStyle(PocketMonkColors.plum.color(for: colorScheme))
            .accessibilityLabel("Your demo balance")
            .accessibilityValue("\(pointBalance) virtual points")
        } else {
            Label("Virtual point balance unavailable", systemImage: "exclamationmark.triangle")
                .font(.subheadline)
                .foregroundStyle(PocketMonkColors.ember.color(for: colorScheme))
        }
    }

    @ViewBuilder
    private var feedbackMessage: some View {
        if let errorMessage = viewModel.errorMessage {
            Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline)
                .foregroundStyle(PocketMonkColors.ember.color(for: colorScheme))
                .accessibilityAddTraits(.updatesFrequently)
        } else if let confirmationMessage = viewModel.confirmationMessage {
            Label(confirmationMessage, systemImage: "checkmark.circle.fill")
                .font(.subheadline)
                .foregroundStyle(PocketMonkColors.jade.color(for: colorScheme))
                .accessibilityAddTraits(.updatesFrequently)
        }
    }

    private var emptyFriendsCard: some View {
        PocketMonkCard {
            VStack(alignment: .leading, spacing: PocketMonkSpacing.medium) {
                PocketMonkSectionLabel(title: "Choose an opponent")
                Text("Accept a friend request before creating a duel.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("Find friends", systemImage: "person.2") {
                    onFindFriends()
                }
                .buttonStyle(.borderedProminent)
                .tint(PocketMonkColors.plum.light.color)
            }
        }
    }

    private var createChallengeButton: some View {
        Button("Create a duel", systemImage: "figure.martial.arts") {
            presentation = .challenge
        }
        .buttonStyle(.borderedProminent)
        .tint(PocketMonkColors.plum.light.color)
        .frame(maxWidth: .infinity, minHeight: 48)
        .disabled(viewModel.pointBalance == nil)
    }

    private var pendingSection: some View {
        Group {
            if !viewModel.pendingDuels.isEmpty {
                VStack(alignment: .leading, spacing: PocketMonkSpacing.medium) {
                    PocketMonkSectionLabel(title: "Awaiting response")
                    ForEach(viewModel.pendingDuels) { duel in
                        PendingDuelCard(
                            duel: duel,
                            accept: {
                                _ = viewModel.acceptDuel(
                                    id: duel.id,
                                    currentZenScore: dashboardSnapshot?.zenScore
                                )
                            },
                            decline: { _ = viewModel.declineDuel(id: duel.id) }
                        )
                    }
                }
            }
        }
    }

    private var activeSection: some View {
        Group {
            if !viewModel.activeDuels.isEmpty {
                VStack(alignment: .leading, spacing: PocketMonkSpacing.medium) {
                    PocketMonkSectionLabel(title: "Active duels")
                    ForEach(viewModel.activeDuels) { duel in
                        DuelActiveCard(
                            duel: duel,
                            dashboardSnapshot: dashboardSnapshot,
                            didExpire: viewModel.refresh
                        )
                    }
                }
            }
        }
    }

    private var pastChallengesSection: some View {
        Group {
            if !viewModel.finishedDuels.isEmpty || !viewModel.declinedDuels.isEmpty {
                VStack(alignment: .leading, spacing: PocketMonkSpacing.medium) {
                    PocketMonkSectionLabel(title: "Past challenges")
                    ForEach(viewModel.finishedDuels) { duel in
                        finishedDuelCard(duel)
                    }
                    ForEach(viewModel.declinedDuels) { duel in
                        PocketMonkCard {
                            PocketMonkListRow(
                                title: "@\(duel.opponentUsername)",
                                detail: "\(duel.status.title) · \(DuelStake.title(for: duel.stakePoints) ?? "Unknown stake")",
                                systemImage: duel.status.systemImage
                            )
                        }
                    }
                }
            } else if viewModel.pendingDuels.isEmpty && viewModel.activeDuels.isEmpty {
                PocketMonkCard {
                    PocketMonkListRow(
                        title: "No challenges yet",
                        detail: "Create a duel when you’re ready to practice with a friend.",
                        systemImage: "figure.martial.arts"
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func finishedDuelCard(_ duel: DuelRecord) -> some View {
        if duel.winner != nil {
            Button {
                presentation = .result(duel)
            } label: {
                PocketMonkCard {
                    PocketMonkListRow(
                        title: duel.winner?.title ?? "Duel result",
                        detail: "@\(duel.opponentUsername) · \(DuelStake.title(for: duel.stakePoints) ?? "Unknown stake")",
                        systemImage: duel.winner?.systemImage ?? "checkmark.circle"
                    )
                }
            }
            .buttonStyle(.plain)
        } else {
            PocketMonkCard {
                VStack(alignment: .leading, spacing: PocketMonkSpacing.medium) {
                    PocketMonkListRow(
                        title: "Ready to resolve",
                        detail: "@\(duel.opponentUsername) · \(DuelStake.title(for: duel.stakePoints) ?? "Unknown stake")",
                        systemImage: "checkmark.circle"
                    )
                    Button(
                        resolvingDuelID == duel.id ? "Updating score…" : "Resolve result",
                        systemImage: "trophy"
                    ) {
                        Task {
                            await resolve(duel)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(PocketMonkColors.plum.light.color)
                    .disabled(dashboardSnapshot == nil || resolvingDuelID == duel.id)
                    if dashboardSnapshot == nil {
                        Text("Your current zen score is needed to resolve this duel.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @MainActor
    private func resolve(_ duel: DuelRecord) async {
        resolvingDuelID = duel.id
        await dashboardViewModel.loadDashboard()
        defer { resolvingDuelID = nil }
        guard viewModel.resolveDuel(
            id: duel.id,
            currentZenScore: dashboardSnapshot?.zenScore
        ) else {
            return
        }
        if let resolvedDuel = viewModel.finishedDuels.first(where: {
            $0.id == duel.id
        }) {
            presentation = .result(resolvedDuel)
        }
    }
}

private enum DuelsPresentation: Identifiable {
    case challenge
    case result(DuelRecord)

    var id: String {
        switch self {
        case .challenge:
            "challenge"
        case let .result(duel):
            "result-\(duel.id.uuidString)"
        }
    }
}

private struct PendingDuelCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let duel: DuelRecord
    let accept: () -> Void
    let decline: () -> Void

    var body: some View {
        PocketMonkCard {
            VStack(alignment: .leading, spacing: PocketMonkSpacing.medium) {
                HStack {
                    VStack(alignment: .leading, spacing: PocketMonkSpacing.extraSmall) {
                        Text("@\(duel.opponentUsername)")
                            .font(.headline)
                        Text("Waiting for your friend to respond")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    PocketMonkStatusPill(
                        title: duel.status.title,
                        color: PocketMonkColors.plum
                    )
                }

                Label(
                    DuelRules.durationLabel(
                        for: duel.duration,
                        seconds: duel.durationSeconds
                    ),
                    systemImage: "calendar"
                )
                Label(
                    DuelStake.title(for: duel.stakePoints) ?? "Unknown stake",
                    systemImage: "sparkles"
                )
                .foregroundStyle(PocketMonkColors.plum.color(for: colorScheme))

                Text("Accept/Decline simulates your opponent’s response in this local demo.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: PocketMonkSpacing.small) {
                    Button("Simulate accept", systemImage: "checkmark", action: accept)
                        .buttonStyle(.borderedProminent)
                        .tint(PocketMonkColors.jade.light.color)
                        .disabled(duel.status != .pending)
                    Button("Decline", systemImage: "xmark", action: decline)
                        .buttonStyle(.bordered)
                        .disabled(duel.status != .pending)
                }
            }
        }
    }
}

#Preview("Duels") {
    NavigationStack {
        DuelsView()
    }
    .modelContainer(for: [FriendRecord.self, DuelRecord.self, DuelPointAccount.self])
}
