import SwiftUI

struct AccountAccessView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: RootViewModel
    @State private var isShowingAuthenticationNotice = false

    var body: some View {
        VStack(alignment: .leading, spacing: PocketMonkSpacing.large) {
            PocketMonkStatusPill(title: "Your account", color: PocketMonkColors.plum)

            VStack(alignment: .leading, spacing: PocketMonkSpacing.small) {
                Text("Stay connected")
                    .font(.largeTitle.bold())
                Text("Sign up or log in to connect with friends. Account services are not connected in this build.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            PocketMonkCard {
                VStack(spacing: PocketMonkSpacing.medium) {
                    accountAction(
                        title: "Sign up",
                        detail: "Create a Pocket Monk account",
                        systemImage: "person.badge.plus"
                    )
                    Divider()
                    accountAction(
                        title: "Log in",
                        detail: "I already have an account",
                        systemImage: "person.crop.circle"
                    )
                }
            }

            PocketMonkButton(
                title: "Continue as guest",
                systemImage: "arrow.right"
            ) {
                viewModel.continueAsGuest()
            }

            Spacer(minLength: 0)
        }
        .padding(PocketMonkSpacing.large)
        .frame(maxWidth: 640, alignment: .leading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(PocketMonkColors.canvas.color(for: colorScheme))
        .alert("Account setup is not connected", isPresented: $isShowingAuthenticationNotice) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Account services will be added after a backend is selected. Continue as a guest to finish setup.")
        }
    }

    private func accountAction(title: String, detail: String, systemImage: String) -> some View {
        Button {
            isShowingAuthenticationNotice = true
        } label: {
            PocketMonkListRow(title: title, detail: detail, systemImage: systemImage)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Account service is not connected in this build")
    }
}

#Preview {
    AccountAccessView(viewModel: RootViewModel(initialState: .accountAccess))
}
