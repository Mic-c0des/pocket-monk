import SwiftUI

struct ScreenTimePermissionView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: RootViewModel
    let isBlocked: Bool

    private var actionTitle: String {
        switch viewModel.permissionStatus {
        case .notDetermined:
            "Allow Screen Time access"
        case .denied:
            "Check access again"
        case .approved:
            "Continue"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PocketMonkSpacing.large) {
            PocketMonkStatusPill(
                title: isBlocked ? "Access needed" : "One last step",
                color: isBlocked ? PocketMonkColors.ember : PocketMonkColors.jade
            )

            VStack(alignment: .leading, spacing: PocketMonkSpacing.small) {
                Text("Connect Screen Time")
                    .font(.largeTitle.bold())
                Text("Pocket Monk needs Screen Time access to prepare your daily practice summary. iOS will ask you to approve access.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            PocketMonkCard {
                PocketMonkListRow(
                    title: permissionTitle,
                    detail: permissionDetail,
                    systemImage: permissionIcon
                )
            }

            if let errorMessage = viewModel.permissionErrorMessage {
                Text("Couldn’t request Screen Time access: \(errorMessage)")
                    .font(.subheadline)
                    .foregroundStyle(PocketMonkColors.ember.color(for: colorScheme))
                    .accessibilityAddTraits(.isStaticText)
            }

            if viewModel.isRequestingPermission {
                HStack(spacing: PocketMonkSpacing.small) {
                    ProgressView()
                    Text("Waiting for your response…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            }

            Spacer(minLength: 0)

            PocketMonkButton(title: actionTitle, systemImage: buttonIcon, action: handleAction)
                .disabled(viewModel.isRequestingPermission)
        }
        .padding(PocketMonkSpacing.large)
        .frame(maxWidth: 640, alignment: .leading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(PocketMonkColors.canvas.color(for: colorScheme))
    }

    private var permissionTitle: String {
        switch viewModel.permissionStatus {
        case .notDetermined: "Screen Time access is not set up"
        case .denied: "Screen Time access is off"
        case .approved: "Screen Time access is on"
        }
    }

    private var permissionDetail: String {
        switch viewModel.permissionStatus {
        case .notDetermined:
            "You can review and approve access in the iOS prompt."
        case .denied:
            "Manage access in Settings, then return here to check again."
        case .approved:
            "You’re ready to continue to Pocket Monk."
        }
    }

    private var permissionIcon: String {
        switch viewModel.permissionStatus {
        case .notDetermined: "hourglass"
        case .denied: "lock"
        case .approved: "checkmark.shield"
        }
    }

    private var buttonIcon: String {
        viewModel.permissionStatus == .approved ? "arrow.right" : "hourglass"
    }

    private func handleAction() {
        switch viewModel.permissionStatus {
        case .notDetermined:
            Task {
                await viewModel.requestScreenTimePermission()
            }
        case .denied:
            viewModel.refreshPermissionState()
        case .approved:
            viewModel.continueWithApprovedPermission()
        }
    }
}

#Preview("Permission gate") {
    ScreenTimePermissionView(
        viewModel: RootViewModel(initialState: .permissionGate),
        isBlocked: false
    )
}
