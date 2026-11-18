import SwiftUI
import SwiftData

struct FriendsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: FriendsViewModel
    @State private var usernameInput = ""
    @State private var inviteLinkInput = ""

    private let incomingInviteURL: URL?
    private let onInviteHandled: () -> Void

    init(
        viewModel: FriendsViewModel? = nil,
        incomingInviteURL: URL? = nil,
        onInviteHandled: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(
            wrappedValue: viewModel ?? FriendsViewModel()
        )
        self.incomingInviteURL = incomingInviteURL
        self.onInviteHandled = onInviteHandled
    }

    var body: some View {
        Group {
            if !viewModel.hasLoaded {
                ProgressView("Loading your circle…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityLabel("Loading your friends")
            } else if let message = viewModel.loadErrorMessage {
                VStack(spacing: PocketMonkSpacing.medium) {
                    Label("We couldn’t load your circle.", systemImage: "exclamationmark.triangle")
                        .font(.headline)
                        .foregroundStyle(PocketMonkColors.ember.color(for: colorScheme))
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Try again", systemImage: "arrow.clockwise") {
                        viewModel.load()
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
                        feedbackMessage
                        addByUsernameCard
                        inviteCard
                        incomingRequestsCard
                        outgoingRequestsCard
                        friendsCard
                    }
                    .padding(PocketMonkSpacing.large)
                    .frame(maxWidth: 640, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .top)
                }
            }
        }
        .background(PocketMonkColors.canvas.color(for: colorScheme))
        .navigationTitle("Friends")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: incomingInviteURL) {
            viewModel.load(using: modelContext)
            guard let incomingInviteURL else { return }
            _ = viewModel.addByInviteLink(incomingInviteURL)
            onInviteHandled()
        }
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: PocketMonkSpacing.small) {
            Text("Your circle")
                .font(.largeTitle.bold())
            Text("Find friends and encourage each other to find balance.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var demoNotice: some View {
        Label(
            "Local demo only — requests stay on this device.",
            systemImage: "iphone"
        )
        .font(.subheadline)
        .foregroundStyle(PocketMonkColors.plum.color(for: colorScheme))
        .padding(.vertical, PocketMonkSpacing.extraSmall)
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

    private var addByUsernameCard: some View {
        PocketMonkCard {
            VStack(alignment: .leading, spacing: PocketMonkSpacing.medium) {
                PocketMonkSectionLabel(title: "Add by username")
                HStack(spacing: PocketMonkSpacing.small) {
                    TextField("Enter a username", text: $usernameInput)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.send)
                        .onSubmit(addFriend)
                        .accessibilityLabel("Friend username")

                    Button("Add", systemImage: "person.badge.plus", action: addFriend)
                        .buttonStyle(.borderedProminent)
                        .tint(PocketMonkColors.jade.light.color)
                }
                Text("Try ava, kai, luna, noah, or sage in this local demo.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var inviteCard: some View {
        PocketMonkCard {
            VStack(alignment: .leading, spacing: PocketMonkSpacing.medium) {
                PocketMonkSectionLabel(title: "Invite link")
                Text("Share a link that expires in seven days, or paste a friend’s link.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let inviteURL = viewModel.inviteURL {
                    ShareLink(item: inviteURL.absoluteString) {
                        Label("Share invite link", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.bordered)
                }

                TextField("Paste an invite link", text: $inviteLinkInput, axis: .vertical)
                    .lineLimit(1...3)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Invite link")

                Button("Add from invite", systemImage: "link") {
                    _ = viewModel.addByInviteLink(inviteLinkInput)
                }
                .buttonStyle(.bordered)
                .disabled(inviteLinkInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private var incomingRequestsCard: some View {
        PocketMonkCard {
            VStack(alignment: .leading, spacing: PocketMonkSpacing.medium) {
                PocketMonkSectionLabel(title: "Incoming requests")

                if viewModel.incomingRequests.isEmpty {
                    Text("No incoming requests yet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Simulate a demo request", systemImage: "person.badge.plus") {
                        _ = viewModel.createDemoIncomingRequest()
                    }
                    .buttonStyle(.bordered)
                } else {
                    ForEach(viewModel.incomingRequests) { request in
                        IncomingFriendRequestRow(
                            request: request,
                            accept: { _ = viewModel.acceptRequest(id: request.id) },
                            decline: { _ = viewModel.declineRequest(id: request.id) }
                        )
                        if request.id != viewModel.incomingRequests.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private var outgoingRequestsCard: some View {
        PocketMonkCard {
            VStack(alignment: .leading, spacing: PocketMonkSpacing.medium) {
                PocketMonkSectionLabel(title: "Sent requests")

                if viewModel.outgoingRequests.isEmpty {
                    Text("Requests you send will appear here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.outgoingRequests) { request in
                        PocketMonkListRow(
                            title: "@\(request.username)",
                            detail: request.status.title,
                            systemImage: request.status.systemImage
                        )
                    }
                }
            }
        }
    }

    private var friendsCard: some View {
        PocketMonkCard {
            VStack(alignment: .leading, spacing: PocketMonkSpacing.medium) {
                PocketMonkSectionLabel(title: "Your friends")

                if viewModel.friends.isEmpty {
                    Text("Your circle is ready for its first connection.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.friends) { friend in
                        PocketMonkListRow(
                            title: "@\(friend.username)",
                            detail: "Ready for future challenges",
                            systemImage: FriendRelationshipStatus.friends.systemImage
                        )
                    }
                }
            }
        }
    }

    private func addFriend() {
        if viewModel.addByUsername(usernameInput) {
            usernameInput = ""
        }
    }
}

private struct IncomingFriendRequestRow: View {
    let request: FriendRecord
    let accept: () -> Void
    let decline: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PocketMonkSpacing.small) {
            HStack(spacing: PocketMonkSpacing.small) {
                Image(systemName: request.status.systemImage)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: PocketMonkSpacing.extraSmall) {
                    Text("@\(request.username)")
                        .font(.headline)
                    Text("Wants to connect")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: PocketMonkSpacing.small)
            }

            HStack(spacing: PocketMonkSpacing.small) {
                Button("Accept", systemImage: "checkmark", action: accept)
                    .buttonStyle(.borderedProminent)
                    .tint(PocketMonkColors.jade.light.color)
                    .frame(minHeight: 44)
                Button("Decline", systemImage: "xmark", action: decline)
                    .buttonStyle(.bordered)
                    .frame(minHeight: 44)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

#Preview("Friends") {
    NavigationStack {
        FriendsView()
    }
    .modelContainer(for: FriendRecord.self)
}
