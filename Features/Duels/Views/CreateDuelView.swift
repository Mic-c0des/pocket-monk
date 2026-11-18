import SwiftUI

struct CreateDuelView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: DuelsViewModel
    @State private var step: DuelCreationStep = .opponent
    @State private var draft: DuelDraft
    @FocusState private var isCustomStakeFocused: Bool

    init(viewModel: DuelsViewModel, initialRival: FriendProfile? = nil) {
        self.viewModel = viewModel
        _draft = State(initialValue: DuelDraft(rival: initialRival))
    }

    private var busyRivalIDs: Set<UUID> {
        viewModel.busyRivalIDs(at: .now)
    }

    private var stepError: DuelError? {
        draft.validationError(for: step, busyRivalIDs: busyRivalIDs)
    }

    private var canAdvance: Bool {
        stepError == nil && !viewModel.isCreatingDuel
    }

    private var rivalFirstName: String {
        draft.rival?.displayName.split(separator: " ").first.map(String.init) ?? "your rival"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: PocketMonkSpacing.large) {
                    stepHeader
                    stepContent

                    if let message = viewModel.createDuelErrorMessage {
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(PocketMonkColors.ember.color(for: colorScheme))
                    }
                }
                .padding(PocketMonkSpacing.large)
                .frame(maxWidth: 640, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .top)
            }
            .background(PocketMonkColors.canvas.color(for: colorScheme))
            .safeAreaInset(edge: .bottom) {
                footer
            }
            .navigationTitle("New duel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .interactiveDismissDisabled(viewModel.isCreatingDuel)
        .task {
            await viewModel.refreshFriends()
        }
        .onAppear {
            viewModel.clearCreateDuelError()
        }
        .onChange(of: draft) {
            viewModel.clearCreateDuelError()
        }
    }

    private var stepHeader: some View {
        VStack(alignment: .leading, spacing: PocketMonkSpacing.small) {
            Text("Step \(step.number) of \(DuelCreationStep.allCases.count)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            ProgressView(value: Double(step.number), total: Double(DuelCreationStep.allCases.count))
                .tint(PocketMonkColors.plum.color(for: colorScheme))
                .accessibilityHidden(true)
            Text(step.title)
                .font(.title2.bold())
                .padding(.top, PocketMonkSpacing.small)
            Text(step.subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .opponent:
            opponentStep
        case .duration:
            durationStep
        case .stake:
            stakeStep
        case .review:
            reviewStep
        }
    }

    // MARK: Opponent

    @ViewBuilder
    private var opponentStep: some View {
        if let friends = viewModel.friends {
            if friends.isEmpty {
                PocketMonkCard {
                    PocketMonkListRow(
                        title: "No friends to challenge yet",
                        detail: "Add a friend in the Friends tab, then come back to start a duel.",
                        systemImage: "person.2"
                    )
                }
            } else {
                PocketMonkCard {
                    VStack(alignment: .leading, spacing: PocketMonkSpacing.small) {
                        ForEach(friends) { friend in
                            rivalOption(friend)
                        }
                    }
                }
                if busyRivalIDs.contains(where: { id in friends.contains { $0.id == id } }) {
                    Text("Friends with an open duel can’t be challenged again until it ends.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } else if let message = viewModel.friendsErrorMessage {
            Text(message)
                .font(.subheadline)
                .foregroundStyle(PocketMonkColors.ember.color(for: colorScheme))
        } else {
            ProgressView("Finding your friends…")
                .frame(maxWidth: .infinity)
        }
    }

    private func rivalOption(_ friend: Friendship) -> some View {
        let isBusy = busyRivalIDs.contains(friend.id)
        let isSelected = draft.rival?.id == friend.id

        return Button {
            draft.rival = friend.profile
        } label: {
            FriendRow(friendship: friend) {
                if isBusy {
                    Text("Open duel")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                } else {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(
                            isSelected ? PocketMonkColors.plum.color(for: colorScheme) : Color.secondary
                        )
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isBusy)
        .opacity(isBusy ? 0.6 : 1)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(isBusy ? "You already have an open duel with this friend." : "")
    }

    // MARK: Duration

    private var durationStep: some View {
        VStack(alignment: .leading, spacing: PocketMonkSpacing.medium) {
            Picker("Duration", selection: $draft.durationOption) {
                ForEach(DuelDurationOption.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.segmented)

            if draft.durationOption == .custom {
                PocketMonkCard {
                    Stepper(value: $draft.customDays, in: DuelDuration.customDayRange) {
                        VStack(alignment: .leading, spacing: PocketMonkSpacing.extraSmall) {
                            Text(draft.duration.title)
                                .font(.headline)
                            Text("Between \(DuelDuration.customDayRange.lowerBound) and \(DuelDuration.customDayRange.upperBound) days")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            PocketMonkCard {
                PocketMonkListRow(
                    title: draft.duration.title,
                    detail: "Starts when \(rivalFirstName) accepts, then runs for \(draft.duration.days * 24) hours.",
                    systemImage: "timer"
                )
            }

            if let stepError {
                Text(stepError.localizedDescription)
                    .font(.subheadline)
                    .foregroundStyle(PocketMonkColors.ember.color(for: colorScheme))
            }
        }
    }

    // MARK: Stake

    private var stakeStep: some View {
        VStack(alignment: .leading, spacing: PocketMonkSpacing.medium) {
            PocketMonkCard {
                VStack(alignment: .leading, spacing: PocketMonkSpacing.small) {
                    ForEach(DuelStakeOption.allCases) { option in
                        stakeOption(option)
                    }
                }
            }

            if draft.stakeOption == .custom {
                VStack(alignment: .leading, spacing: PocketMonkSpacing.small) {
                    TextField("Loser does the dishes", text: $draft.customStake)
                        .focused($isCustomStakeFocused)
                        .submitLabel(.done)
                        .padding(PocketMonkSpacing.medium)
                        .background(
                            PocketMonkColors.surface.color(for: colorScheme),
                            in: RoundedRectangle(cornerRadius: PocketMonkCornerRadius.small)
                        )
                        .accessibilityLabel("Custom stake")

                    HStack(alignment: .firstTextBaseline) {
                        if !draft.customStake.isEmpty, let stepError {
                            Text(stepError.localizedDescription)
                                .font(.subheadline)
                                .foregroundStyle(PocketMonkColors.ember.color(for: colorScheme))
                        }
                        Spacer()
                        Text("\(draft.customStake.count)/\(DuelStake.maximumCustomLength)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                            .accessibilityLabel(
                                "\(draft.customStake.count) of \(DuelStake.maximumCustomLength) characters"
                            )
                    }
                }
            }

            Text("Pocket Monk never handles money. Stakes are promises between friends.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func stakeOption(_ option: DuelStakeOption) -> some View {
        let isSelected = draft.stakeOption == option

        return Button {
            draft.stakeOption = option
            isCustomStakeFocused = option == .custom
        } label: {
            HStack(spacing: PocketMonkSpacing.medium) {
                Image(systemName: option.systemImage)
                    .font(.body)
                    .foregroundStyle(PocketMonkColors.plum.color(for: colorScheme))
                    .frame(width: 32)
                    .accessibilityHidden(true)
                Text(option.title)
                    .font(.body)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(
                        isSelected ? PocketMonkColors.plum.color(for: colorScheme) : Color.secondary
                    )
                    .accessibilityHidden(true)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: Review

    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: PocketMonkSpacing.medium) {
            PocketMonkCard {
                VStack(alignment: .leading, spacing: PocketMonkSpacing.medium) {
                    PocketMonkSectionLabel(title: "Challenge")
                    if let rival = draft.rival {
                        VStack(alignment: .leading, spacing: PocketMonkSpacing.extraSmall) {
                            Text("\(viewModel.currentUser.displayName) vs \(rival.displayName)")
                                .font(.title3.bold())
                            Text("\(viewModel.currentUser.monkName) vs \(rival.monkName)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                    Divider()
                    reviewRow(title: "Duration", value: draft.duration.title, systemImage: "timer", step: .duration)
                    reviewRow(
                        title: "Stake",
                        value: (try? draft.stake())?.title ?? "Not set",
                        systemImage: (try? draft.stake())?.systemImage ?? "pencil",
                        step: .stake
                    )
                }
            }

            PocketMonkCard {
                VStack(alignment: .leading, spacing: PocketMonkSpacing.small) {
                    PocketMonkSectionLabel(title: "How it’s decided")
                    Text("Each monk is scored against its own baseline, so the duel rewards whoever cuts back more, not whoever uses their phone least.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let stepError {
                Text(stepError.localizedDescription)
                    .font(.subheadline)
                    .foregroundStyle(PocketMonkColors.ember.color(for: colorScheme))
            }
        }
    }

    private func reviewRow(
        title: String,
        value: String,
        systemImage: String,
        step target: DuelCreationStep
    ) -> some View {
        HStack(spacing: PocketMonkSpacing.medium) {
            Image(systemName: systemImage)
                .foregroundStyle(PocketMonkColors.plum.color(for: colorScheme))
                .frame(width: 32)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: PocketMonkSpacing.extraSmall) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.body)
            }
            .accessibilityElement(children: .combine)
            Spacer()
            Button("Edit") {
                withAnimation {
                    step = target
                }
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Edit \(title.lowercased())")
        }
    }

    // MARK: Footer

    private var footer: some View {
        HStack(spacing: PocketMonkSpacing.medium) {
            if let previous = step.previous {
                Button("Back", systemImage: "chevron.left") {
                    withAnimation {
                        step = previous
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }

            if viewModel.isCreatingDuel {
                ProgressView("Sending…")
                    .frame(maxWidth: .infinity, minHeight: 48)
            } else {
                PocketMonkButton(
                    title: step.isFinal ? "Send challenge" : "Next",
                    systemImage: step.isFinal ? "paperplane" : "arrow.right",
                    action: advance
                )
                .disabled(!canAdvance)
            }
        }
        .padding(.horizontal, PocketMonkSpacing.large)
        .padding(.vertical, PocketMonkSpacing.mediumSmall)
        .background(.bar)
    }

    private func advance() {
        guard canAdvance else { return }

        if let next = step.next {
            isCustomStakeFocused = false
            withAnimation {
                step = next
            }
            return
        }

        Task {
            if await viewModel.createDuel(from: draft) {
                dismiss()
            }
        }
    }
}

#Preview("New duel") {
    CreateDuelView(viewModel: .preview())
}

#Preview("Challenge Sage") {
    CreateDuelView(viewModel: .preview(), initialRival: SampleFriendsData.sage)
}
