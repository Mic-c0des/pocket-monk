import SwiftUI

struct DuelsView: View {
    @StateObject private var viewModel: DuelsViewModel
    @Binding private var challengeRequest: FriendProfile?
    @State private var isShowingNewDuel = false
    @State private var newDuelRival: FriendProfile?

    /// `challengeRequest` lets another tab open the new-duel flow with a rival already chosen.
    init(
        viewModel: DuelsViewModel? = nil,
        challengeRequest: Binding<FriendProfile?> = .constant(nil)
    ) {
        _viewModel = StateObject(wrappedValue: viewModel ?? DuelsViewModel())
        _challengeRequest = challengeRequest
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView("Gathering your duels…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityLabel("Loading your duels")
            case let .loaded(book):
                DuelsContentView(viewModel: viewModel, book: book) {
                    startNewDuel()
                }
            case let .failed(message):
                PocketMonkMessageView(
                    title: "We couldn’t load your duels",
                    detail: message,
                    systemImage: "exclamationmark.triangle"
                ) {
                    Button("Try again", systemImage: "arrow.clockwise", action: reload)
                        .buttonStyle(.bordered)
                }
            }
        }
        .navigationTitle("Duels")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("New duel", systemImage: "plus") {
                    startNewDuel()
                }
            }
        }
        .sheet(isPresented: $isShowingNewDuel) {
            CreateDuelView(viewModel: viewModel, initialRival: newDuelRival)
        }
        .alert("Something went wrong", isPresented: isShowingActionError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.actionErrorMessage ?? "")
        }
        .task {
            await viewModel.load()
        }
        .onChange(of: challengeRequest?.id, initial: true) {
            guard let rival = challengeRequest else { return }
            challengeRequest = nil
            startNewDuel(with: rival)
        }
    }

    private var isShowingActionError: Binding<Bool> {
        Binding(
            get: { viewModel.actionErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.dismissActionError()
                }
            }
        )
    }

    private func startNewDuel(with rival: FriendProfile? = nil) {
        newDuelRival = rival
        isShowingNewDuel = true
    }

    private func reload() {
        Task {
            await viewModel.load()
        }
    }
}

private struct DuelsContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: DuelsViewModel

    let book: DuelBook
    let startNewDuel: () -> Void

    var body: some View {
        ScrollView {
            // Ticks every second so countdowns stay current and finished duels move down on their own.
            TimelineView(.periodic(from: .now, by: 1)) { context in
                sections(at: context.date)
            }
            .padding(PocketMonkSpacing.large)
            .frame(maxWidth: 640, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .background(PocketMonkColors.canvas.color(for: colorScheme))
        .refreshable {
            await viewModel.load()
        }
    }

    private func sections(at date: Date) -> some View {
        let activeDuels = book.activeDuels(at: date)
        let finishedDuels = book.finishedDuels(at: date)

        return LazyVStack(alignment: .leading, spacing: PocketMonkSpacing.large) {
            header
            if !book.incomingChallenges.isEmpty {
                incomingCard(at: date)
            }
            activeCard(activeDuels, at: date)
            if !book.outgoingChallenges.isEmpty {
                outgoingCard(at: date)
            }
            if !finishedDuels.isEmpty {
                finishedCard(finishedDuels, at: date)
            }
            Text(SampleDuelsData.tryItHint)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: PocketMonkSpacing.small) {
            Text("Friendly challenges")
                .font(.largeTitle.bold())
            Text("Challenge a friend and see whose monk stays calmer.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private func incomingCard(at date: Date) -> some View {
        PocketMonkCard {
            VStack(alignment: .leading, spacing: PocketMonkSpacing.medium) {
                PocketMonkSectionLabel(title: "Challenges for you")
                ForEach(book.incomingChallenges) { duel in
                    DuelRow(duel: duel, date: date) {
                        HStack(spacing: PocketMonkSpacing.small) {
                            Button("Decline", systemImage: "xmark") {
                                Task {
                                    await viewModel.declineDuel(duel.id)
                                }
                            }
                            .buttonStyle(.bordered)
                            .accessibilityLabel("Decline \(duel.rival.displayName)’s challenge")

                            Button("Accept", systemImage: "checkmark") {
                                Task {
                                    await viewModel.acceptDuel(duel.id)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(PocketMonkColors.plum.color(for: colorScheme))
                            .accessibilityLabel("Accept \(duel.rival.displayName)’s challenge")
                        }
                        .labelStyle(.iconOnly)
                        .disabled(viewModel.isProcessing(duel.id))
                    }
                }
            }
        }
    }

    private func activeCard(_ duels: [Duel], at date: Date) -> some View {
        PocketMonkCard {
            VStack(alignment: .leading, spacing: PocketMonkSpacing.medium) {
                PocketMonkSectionLabel(title: "In progress")

                if duels.isEmpty {
                    Text(emptyActiveMessage)
                        .font(.body)
                        .foregroundStyle(.secondary)
                    Button("Start a duel", systemImage: "figure.martial.arts", action: startNewDuel)
                        .buttonStyle(.bordered)
                } else {
                    ForEach(duels) { duel in
                        detailLink(for: duel, at: date)
                    }
                }
            }
        }
    }

    private func outgoingCard(at date: Date) -> some View {
        PocketMonkCard {
            VStack(alignment: .leading, spacing: PocketMonkSpacing.medium) {
                PocketMonkSectionLabel(title: "Waiting on")
                ForEach(book.outgoingChallenges) { duel in
                    DuelRow(duel: duel, date: date) {
                        Button("Cancel") {
                            Task {
                                await viewModel.cancelDuel(duel.id)
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .accessibilityLabel("Cancel challenge to \(duel.rival.displayName)")
                        .disabled(viewModel.isProcessing(duel.id))
                    }
                }
            }
        }
    }

    private func finishedCard(_ duels: [Duel], at date: Date) -> some View {
        PocketMonkCard {
            VStack(alignment: .leading, spacing: PocketMonkSpacing.medium) {
                PocketMonkSectionLabel(title: "Past duels")
                ForEach(duels) { duel in
                    detailLink(for: duel, at: date)
                }
            }
        }
    }

    private func detailLink(for duel: Duel, at date: Date) -> some View {
        NavigationLink {
            DuelDetailView(viewModel: viewModel, duelID: duel.id)
        } label: {
            DuelRow(duel: duel, date: date) {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var emptyActiveMessage: String {
        if viewModel.friends?.isEmpty == true {
            return "Add a friend in the Friends tab, then challenge them here."
        }
        return "No duels running right now. Challenge a friend to get started."
    }
}

#Preview("Duels") {
    NavigationStack {
        DuelsView(viewModel: .preview())
    }
}

#Preview("No duels") {
    NavigationStack {
        DuelsView(viewModel: .preview(duels: []))
    }
}

extension DuelsViewModel {
    /// A view model backed by in-memory stores, for previews.
    static func preview(duels: [Duel]? = nil, friendships: [Friendship]? = nil) -> DuelsViewModel {
        let friendsService = LocalFriendsService(store: InMemoryFriendshipStore(friendships: friendships))
        return DuelsViewModel(
            service: LocalDuelsService(friendsService: friendsService, store: InMemoryDuelStore(duels: duels)),
            friendsService: friendsService,
            reminders: PreviewDuelReminderScheduler()
        )
    }
}

private struct PreviewDuelReminderScheduler: DuelReminderScheduling {
    func scheduleEndReminder(for duel: Duel, at date: Date) async {}
}
