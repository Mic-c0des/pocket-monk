import SwiftUI

extension DuelStatus {
    var title: String {
        switch self {
        case .pending: "Pending"
        case .active: "Live"
        case .finished: "Finished"
        }
    }

    var colorToken: AdaptiveColorToken {
        switch self {
        case .pending: PocketMonkColors.stone
        case .active: PocketMonkColors.jade
        case .finished: PocketMonkColors.plum
        }
    }
}

struct DuelRow<Accessory: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    let duel: Duel
    let date: Date
    @ViewBuilder let accessory: Accessory

    private var status: DuelStatus {
        duel.status(at: date)
    }

    var body: some View {
        HStack(spacing: PocketMonkSpacing.medium) {
            Image(systemName: duel.isIncoming && duel.isPending ? "envelope.open" : "figure.martial.arts")
                .font(.title3)
                .foregroundStyle(status.colorToken.color(for: colorScheme))
                .frame(width: 44, height: 44)
                .background(status.colorToken.color(for: colorScheme).opacity(0.14), in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: PocketMonkSpacing.extraSmall) {
                Text("vs \(duel.rival.displayName)")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .multilineTextAlignment(.leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Duel with \(duel.rival.displayName)")
            .accessibilityValue(spokenDetail)

            Spacer(minLength: PocketMonkSpacing.small)

            accessory
        }
        .padding(.vertical, PocketMonkSpacing.extraSmall)
    }

    private var detail: String {
        switch status {
        case .pending:
            duel.isIncoming
                ? "\(duel.duration.title) · \(duel.stake.title)"
                : "Waiting to accept · \(duel.duration.title)"
        case .active:
            "\(DuelCountdownFormatter.compact(duel.timeRemaining(at: date) ?? 0)) left · \(duel.stake.title)"
        case .finished:
            "Ended \(endDateText) · \(duel.stake.title)"
        }
    }

    private var spokenDetail: String {
        switch status {
        case .pending:
            duel.isIncoming
                ? "Challenged you. \(duel.duration.title). \(duel.stake.title)."
                : "Waiting for \(duel.rival.displayName) to accept. \(duel.duration.title)."
        case .active:
            "\(DuelCountdownFormatter.spoken(duel.timeRemaining(at: date) ?? 0)). \(duel.stake.title)."
        case .finished:
            "Ended \(endDateText). \(duel.stake.title)."
        }
    }

    private var endDateText: String {
        duel.endsAt?.formatted(.dateTime.month(.abbreviated).day()) ?? ""
    }
}
