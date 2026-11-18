import SwiftData
import SwiftUI

struct DuelsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel: DuelViewModel
    @StateObject private var dashboardViewModel: DashboardViewModel
    @State private var isShowingChallengeFlow = false

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
        ScrollView {
            LazyVStack(alignment: .leading, spacing: PocketMonkSpacing.large) {
                introduction
                demoNotice
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
        .background(PocketMonkColors.canvas.color(for: colorScheme))
        .navigationTitle("Duels")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            viewModel.load(using: modelContext)
            await dashboardViewModel.loadDashboard()
        }
        .sheet(isPresented: $isShowingChallengeFlow) {
            NavigationStack {
                DuelChallengeFlowView(friends: viewModel.friends) {
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
            isShowingChallengeFlow = true
        }
        .buttonStyle(.borderedProminent)
        .tint(PocketMonkColors.plum.light.color)
        .frame(maxWidth: .infinity, minHeight: 48)
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
        let pastDuels = viewModel.finishedDuels + viewModel.declinedDuels
        return Group {
            if !pastDuels.isEmpty {
                VStack(alignment: .leading, spacing: PocketMonkSpacing.medium) {
                    PocketMonkSectionLabel(title: "Past challenges")
                    ForEach(pastDuels) { duel in
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
    .modelContainer(for: [FriendRecord.self, DuelRecord.self])
}
