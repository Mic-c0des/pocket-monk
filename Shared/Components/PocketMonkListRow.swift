import SwiftUI

struct PocketMonkListRow: View {
    let title: String
    let detail: String
    let systemImage: String

    var body: some View {
        HStack(spacing: PocketMonkSpacing.medium) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(PocketMonkColors.jade.light.color)
                .frame(width: 44, height: 44)
                .background(PocketMonkColors.jade.light.color.opacity(0.12), in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: PocketMonkSpacing.extraSmall) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, PocketMonkSpacing.small)
    }
}
