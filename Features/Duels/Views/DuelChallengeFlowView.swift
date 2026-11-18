import SwiftUI

struct DuelChallengeFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let friends: [FriendRecord]
    let onCreate: (String, DuelDurationOption, Date, Int) -> String?

    @State private var step: DuelChallengeStep = .opponent
    @State private var selectedOpponentUsername: String?
    @State private var selectedDuration: DuelDurationOption = .oneDay
    @State private var customEndDate = Date.now.addingTimeInterval(
        TimeInterval(2 * DuelRules.secondsPerDay)
    )
    @State private var stakePoints = 10
    @State private var errorMessage: String?

    init(
        friends: [FriendRecord],
        onCreate: @escaping (String, DuelDurationOption, Date, Int) -> String?
    ) {
        self.friends = friends
        self.onCreate = onCreate
        _selectedOpponentUsername = State(initialValue: friends.first?.username)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PocketMonkSpacing.large) {
                progressIndicator
                stepContent
                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                        .foregroundStyle(PocketMonkColors.ember.color(for: colorScheme))
                        .accessibilityAddTraits(.updatesFrequently)
                }
            }
            .padding(PocketMonkSpacing.large)
        }
        .navigationTitle(step.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(step == .opponent ? "Cancel" : "Back", action: goBack)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(
                    step == .review ? "Send challenge" : "Continue",
                    systemImage: step == .review ? "paperplane" : "arrow.right",
                    action: goForward
                )
                .disabled(isPrimaryActionDisabled)
            }
        }
    }

    private var progressIndicator: some View {
        Text("Step \(step.rawValue + 1) of \(DuelChallengeStep.allCases.count)")
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .opponent:
            opponentSelection
        case .duration:
            durationSelection
        case .stake:
            stakeSelection
        case .review:
            review
        }
    }

    private var opponentSelection: some View {
        VStack(alignment: .leading, spacing: PocketMonkSpacing.medium) {
            Text("Who would you like to challenge?")
                .font(.title2.bold())
            ForEach(friends) { friend in
                Button {
                    selectedOpponentUsername = friend.username
                    errorMessage = nil
                } label: {
                    HStack(spacing: PocketMonkSpacing.medium) {
                        Image(systemName: "person.crop.circle")
                            .font(.title2)
                            .foregroundStyle(PocketMonkColors.plum.light.color)
                            .accessibilityHidden(true)
                        Text("@\(friend.username)")
                            .font(.headline)
                        Spacer()
                        if selectedOpponentUsername == friend.username {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(PocketMonkColors.jade.light.color)
                                .accessibilityLabel("Selected")
                        }
                    }
                    .padding(PocketMonkSpacing.medium)
                    .background(
                        PocketMonkColors.surface.color(for: colorScheme),
                        in: RoundedRectangle(cornerRadius: PocketMonkCornerRadius.medium)
                    )
                    .contentShape(RoundedRectangle(cornerRadius: PocketMonkCornerRadius.medium))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(
                    selectedOpponentUsername == friend.username ? .isSelected : []
                )
            }
        }
    }

    private var durationSelection: some View {
        VStack(alignment: .leading, spacing: PocketMonkSpacing.medium) {
            Text("Set your challenge window")
                .font(.title2.bold())
            Text("The clock starts when the demo opponent accepts.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Picker("Duration", selection: $selectedDuration) {
                ForEach(DuelDurationOption.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.segmented)

            if selectedDuration == .custom {
                DatePicker(
                    "Ends",
                    selection: $customEndDate,
                    in: Date.now.addingTimeInterval(
                        TimeInterval(DuelRules.secondsPerMinute)
                    )...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.compact)
                Text("Choose any future end time. The duration begins at acceptance.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Your challenge will run for \(selectedDuration.title.lowercased()) after it is accepted.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var stakeSelection: some View {
        VStack(alignment: .leading, spacing: PocketMonkSpacing.medium) {
            Text("Choose a friendly stake")
                .font(.title2.bold())
            Text("Each side stakes the same number of virtual points.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Picker("Virtual points per person", selection: $stakePoints) {
                ForEach(DuelStake.pointOptions, id: \.self) { points in
                    Text(DuelStake.title(for: points) ?? "Unavailable")
                        .tag(points)
                }
            }
            .pickerStyle(.inline)

            Label(
                "Points have no monetary value. Results and point settlement come in a later phase.",
                systemImage: "info.circle"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var review: some View {
        VStack(alignment: .leading, spacing: PocketMonkSpacing.medium) {
            Text("Review your challenge")
                .font(.title2.bold())
            PocketMonkCard {
                VStack(alignment: .leading, spacing: PocketMonkSpacing.medium) {
                    reviewRow(title: "Opponent", value: selectedOpponent.map { "@\($0.username)" } ?? "Choose a friend")
                    Divider()
                    reviewRow(title: "Window", value: durationSummary)
                    Divider()
                    reviewRow(
                        title: "Each person stakes",
                        value: DuelStake.title(for: stakePoints) ?? "Choose a stake"
                    )
                }
            }
            Text("Sending creates a pending local challenge. Simulate your friend’s response from the Duels screen.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var selectedOpponent: FriendRecord? {
        friends.first { $0.username == selectedOpponentUsername }
    }

    private var durationSummary: String {
        guard selectedDuration == .custom else {
            return selectedDuration.title
        }
        let durationSeconds = max(1, Int(customEndDate.timeIntervalSinceNow))
        return DuelRules.durationLabel(
            for: .custom,
            seconds: durationSeconds
        )
    }

    private var isPrimaryActionDisabled: Bool {
        switch step {
        case .opponent:
            selectedOpponent == nil
        case .duration:
            selectedDuration == .custom && customEndDate <= .now
        case .stake:
            !DuelStake.pointOptions.contains(stakePoints)
        case .review:
            selectedOpponent == nil || !DuelStake.pointOptions.contains(stakePoints)
        }
    }

    private func reviewRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }

    private func goBack() {
        errorMessage = nil
        if let previousStep = step.previous {
            step = previousStep
        } else {
            dismiss()
        }
    }

    private func goForward() {
        errorMessage = nil
        guard !isPrimaryActionDisabled else { return }

        guard let nextStep = step.next else {
            guard let selectedOpponentUsername else { return }
            errorMessage = onCreate(
                selectedOpponentUsername,
                selectedDuration,
                customEndDate,
                stakePoints
            )
            if errorMessage == nil {
                dismiss()
            }
            return
        }
        step = nextStep
    }
}

private enum DuelChallengeStep: Int, CaseIterable {
    case opponent
    case duration
    case stake
    case review

    var title: String {
        switch self {
        case .opponent: "Choose opponent"
        case .duration: "Challenge window"
        case .stake: "Virtual stake"
        case .review: "Review"
        }
    }

    var next: DuelChallengeStep? {
        DuelChallengeStep(rawValue: rawValue + 1)
    }

    var previous: DuelChallengeStep? {
        DuelChallengeStep(rawValue: rawValue - 1)
    }
}
