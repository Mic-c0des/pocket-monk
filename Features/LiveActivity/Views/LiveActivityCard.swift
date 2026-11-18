import SwiftUI

struct LiveActivityCard: View {
    @StateObject private var viewModel: LiveActivityViewModel

    let snapshot: DashboardSnapshot

    init(
        snapshot: DashboardSnapshot,
        viewModel: LiveActivityViewModel? = nil
    ) {
        self.snapshot = snapshot
        _viewModel = StateObject(
            wrappedValue: viewModel ?? LiveActivityViewModel()
        )
    }

    var body: some View {
        PocketMonkCard {
            VStack(alignment: .leading, spacing: PocketMonkSpacing.medium) {
                PocketMonkSectionLabel(title: "Lock Screen")
                Text(viewModel.presentation.title)
                    .font(.headline)
                Text(viewModel.presentation.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let actionTitle = viewModel.presentation.actionTitle {
                    Button(actionTitle) {
                        Task {
                            await viewModel.performAction(snapshot: snapshot)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.presentation.isActionEnabled)
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .accessibilityAddTraits(.updatesFrequently)
                }
            }
        }
        .task(id: snapshot.zenScore) {
            await viewModel.refreshIfActive(snapshot: snapshot)
        }
    }
}
