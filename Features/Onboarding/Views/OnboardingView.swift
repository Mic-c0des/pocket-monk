import SwiftUI

struct OnboardingView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: RootViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: PocketMonkSpacing.large) {
            PocketMonkStatusPill(title: "Welcome", color: PocketMonkColors.plum)

            VStack(alignment: .leading, spacing: PocketMonkSpacing.small) {
                Text("A little more calm, one day at a time.")
                    .font(.largeTitle.bold())
                Text("Pocket Monk helps you build a healthier relationship with your screen time.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            PocketMonkCard {
                PocketMonkListRow(
                    title: "Meet your monk",
                    detail: "Your monk’s mood will reflect your daily screen-time habits.",
                    systemImage: "figure.mind.and.body"
                )
            }

            Spacer(minLength: 0)

            PocketMonkButton(title: "Get started", systemImage: "arrow.right") {
                viewModel.continueToAccountAccess()
            }
        }
        .padding(PocketMonkSpacing.large)
        .frame(maxWidth: 640, alignment: .leading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(PocketMonkColors.canvas.color(for: colorScheme))
    }
}

#Preview {
    OnboardingView(viewModel: RootViewModel(initialState: .onboarding))
}
