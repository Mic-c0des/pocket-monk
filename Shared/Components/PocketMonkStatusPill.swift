import SwiftUI

struct PocketMonkStatusPill: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let color: AdaptiveColorToken

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, PocketMonkSpacing.medium)
            .padding(.vertical, PocketMonkSpacing.small)
            .foregroundStyle(color.color(for: colorScheme))
            .background(color.color(for: colorScheme).opacity(0.14), in: Capsule())
            .accessibilityAddTraits(.isStaticText)
    }
}
