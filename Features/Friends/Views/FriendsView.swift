import SwiftUI

struct FriendsView: View {
    @StateObject private var viewModel: FriendsViewModel
    @State private var isShowingAddFriend = false

    private let onChallenge: ((FriendProfile) -> Void)?

    /// `onChallenge` adds a "Challenge to a duel" action to each friend when provided.
    init(viewModel: FriendsViewModel? = nil, onChallenge: ((FriendProfile) -> Void)? = nil) {
        _viewModel = StateObject(
            wrappedValue: viewModel ?? FriendsViewModel()
        )
        self.onChallenge = onChallenge
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView("Gathering your circle…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityLabel("Loading your friends")
            case let .loaded(graph):
                FriendsContentView(
                    viewModel: viewModel,
                    graph: graph,
                    addFriend: showAddFriend,
                    onChallenge: onChallenge
                )
            case let .failed(message):
                PocketMonkMessageView(
                    title: "We couldn’t load your friends",
                    detail: message,
                    systemImage: "exclamationmark.triangle"
                ) {
                    Button("Try again", systemImage: "arrow.clockwise", action: reload)
                        .buttonStyle(.bordered)
                }
            }
        }
        .navigationTitle("Friends")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add friend", systemImage: "person.badge.plus", action: showAddFriend)
            }
        }
        .sheet(isPresented: $isShowingAddFriend) {
            AddFriendView(viewModel: viewModel)
        }
        .alert("Something went wrong", isPresented: isShowingActionError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.actionErrorMessage ?? "")
        }
        .task {
            await viewModel.load()
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

    private func showAddFriend() {
        isShowingAddFriend = true
    }

    private func reload() {
        Task {
            await viewModel.load()
        }
    }
}

private struct FriendsContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: FriendsViewModel
    @State private var friendPendingRemoval: Friendship?

    let graph: FriendGraph
    let addFriend: () -> Void
    let onChallenge: ((FriendProfile) -> Void)?

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: PocketMonkSpacing.large) {
                header
                InviteCard(inviteLink: viewModel.inviteLink)
                if !graph.incomingRequests.isEmpty {
                    requestsCard
                }
                friendsCard
                if !graph.outgoingRequests.isEmpty {
                    sentRequestsCard
                }
            }
            .padding(PocketMonkSpacing.large)
            .frame(maxWidth: 640, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .background(PocketMonkColors.canvas.color(for: colorScheme))
        .refreshable {
            await viewModel.load()
        }
        .confirmationDialog(
            "Remove friend?",
            isPresented: isConfirmingRemoval,
            titleVisibility: .visible,
            presenting: friendPendingRemoval
        ) { friendship in
            Button("Remove \(friendship.profile.displayName)", role: .destructive) {
                Task {
                    await viewModel.removeFriend(friendship.id)
                }
            }
        } message: { friendship in
            Text("You and \(friendship.profile.displayName) won’t be able to challenge each other until you reconnect.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: PocketMonkSpacing.small) {
            Text("Your circle")
                .font(.largeTitle.bold())
            Text("Add friends and keep each other accountable.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var requestsCard: some View {
        PocketMonkCard {
            VStack(alignment: .leading, spacing: PocketMonkSpacing.medium) {
                PocketMonkSectionLabel(title: "Requests")
                ForEach(graph.incomingRequests) { request in
                    FriendRow(friendship: request) {
                        HStack(spacing: PocketMonkSpacing.small) {
                            Button("Decline", systemImage: "xmark") {
                                Task {
                                    await viewModel.declineRequest(from: request.id)
                                }
                            }
                            .buttonStyle(.bordered)
                            .accessibilityLabel("Decline \(request.profile.displayName)")

                            Button("Accept", systemImage: "checkmark") {
                                Task {
                                    await viewModel.acceptRequest(from: request.id)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .accessibilityLabel("Accept \(request.profile.displayName)")
                        }
                        .labelStyle(.iconOnly)
                        .disabled(viewModel.isProcessing(request.id))
                    }
                }
            }
        }
    }

    private var friendsCard: some View {
        PocketMonkCard {
            VStack(alignment: .leading, spacing: PocketMonkSpacing.medium) {
                PocketMonkSectionLabel(title: "Friends")

                if graph.friends.isEmpty {
                    Text("No friends yet. Invite someone to keep each other accountable.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    Button("Add a friend", systemImage: "person.badge.plus", action: addFriend)
                        .buttonStyle(.bordered)
                } else {
                    ForEach(graph.friends) { friend in
                        FriendRow(friendship: friend) {
                            Menu {
                                if let onChallenge {
                                    Button("Challenge to a duel", systemImage: "figure.martial.arts") {
                                        onChallenge(friend.profile)
                                    }
                                }
                                Button("Remove friend", systemImage: "person.badge.minus", role: .destructive) {
                                    friendPendingRemoval = friend
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .frame(width: 44, height: 44)
                                    .contentShape(Rectangle())
                            }
                            .accessibilityLabel("Options for \(friend.profile.displayName)")
                            .disabled(viewModel.isProcessing(friend.id))
                        }
                    }
                }
            }
        }
    }

    private var sentRequestsCard: some View {
        PocketMonkCard {
            VStack(alignment: .leading, spacing: PocketMonkSpacing.medium) {
                PocketMonkSectionLabel(title: "Sent requests")
                ForEach(graph.outgoingRequests) { request in
                    FriendRow(friendship: request) {
                        Button("Cancel") {
                            Task {
                                await viewModel.cancelRequest(to: request.id)
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .accessibilityLabel("Cancel request to \(request.profile.displayName)")
                        .disabled(viewModel.isProcessing(request.id))
                    }
                }
            }
        }
    }

    private var isConfirmingRemoval: Binding<Bool> {
        Binding(
            get: { friendPendingRemoval != nil },
            set: { isPresented in
                if !isPresented {
                    friendPendingRemoval = nil
                }
            }
        )
    }
}

private struct InviteCard: View {
    let inviteLink: URL?

    var body: some View {
        PocketMonkCard {
            VStack(alignment: .leading, spacing: PocketMonkSpacing.medium) {
                PocketMonkSectionLabel(title: "Invite")
                Text("Bring a friend into your circle")
                    .font(.headline)
                Text("Anyone who opens your link joins your circle right away.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let inviteLink {
                    ShareLink(
                        item: inviteLink,
                        message: Text("Join my Pocket Monk circle and let’s find some calm together.")
                    ) {
                        Label("Share invite link", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(PocketMonkColors.jade.light.color)
                } else {
                    Text(FriendInviteError.linkUnavailable.localizedDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text("Invite links will work for other people once account services are connected.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview("Friends") {
    NavigationStack {
        FriendsView(
            viewModel: FriendsViewModel(service: LocalFriendsService(store: InMemoryFriendshipStore()))
        )
    }
}

#Preview("No friends") {
    NavigationStack {
        FriendsView(
            viewModel: FriendsViewModel(
                service: LocalFriendsService(store: InMemoryFriendshipStore(friendships: []))
            )
        )
    }
}
