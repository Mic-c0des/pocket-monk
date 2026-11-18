import SwiftUI

struct PocketMonkMessageView<Action: View>: View {
    let title: String
    let detail: String
    let systemImage: String
    @ViewBuilder let action: Action

    var body: some View {
        VStack(spacing: PocketMonkSpacing.medium) {
            Image(systemName: systemImage)
                .font(.largeTitle)
                .accessibilityHidden(true)
            Text(title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text(detail)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            action
        }
        .padding(PocketMonkSpacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
