import SwiftUI

struct FriendRow<Accessory: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    let friendship: Friendship
    @ViewBuilder let accessory: Accessory

    var body: some View {
        HStack(spacing: PocketMonkSpacing.medium) {
            Text(initial)
                .font(.headline)
                .foregroundStyle(PocketMonkColors.plum.color(for: colorScheme))
                .frame(width: 44, height: 44)
                .background(PocketMonkColors.plum.color(for: colorScheme).opacity(0.14), in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: PocketMonkSpacing.extraSmall) {
                Text(friendship.profile.displayName)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)

            Spacer(minLength: PocketMonkSpacing.small)

            accessory
        }
        .padding(.vertical, PocketMonkSpacing.extraSmall)
    }

    private var initial: String {
        friendship.profile.displayName.first.map { String($0).uppercased() } ?? "?"
    }

    private var detail: String {
        let handle = "@\(friendship.profile.username)"
        return switch friendship.status {
        case .accepted: "\(handle) · \(friendship.profile.monkName) the monk"
        case .incoming: "\(handle) wants to join your circle"
        case .outgoing: "\(handle) · Request sent"
        }
    }
}
