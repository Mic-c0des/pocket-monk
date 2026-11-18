import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel: RootViewModel

    init(initialState: AppFlowState? = nil) {
        _viewModel = StateObject(
            wrappedValue: RootViewModel(initialState: initialState)
        )
    }

    var body: some View {
        Group {
            switch viewModel.flowState {
            case .loading:
                AppFlowPlaceholderView(
                    title: "Preparing your space",
                    detail: "Your Pocket Monk is getting ready."
                )
            case .onboarding:
                OnboardingView(viewModel: viewModel)
            case .accountAccess:
                AccountAccessView(viewModel: viewModel)
            case .permissionGate:
                ScreenTimePermissionView(viewModel: viewModel, isBlocked: false)
            case .blocked:
                ScreenTimePermissionView(viewModel: viewModel, isBlocked: true)
            case .ready:
                RootTabView()
            }
        }
        .tint(PocketMonkColors.jade.light.color)
        .task {
            viewModel.load()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            viewModel.refreshPermissionState()
        }
    }
}

private struct RootTabView: View {
    @State private var selectedTab: AppTab = .dashboard
    @State private var incomingInviteURL: URL?
    private let analytics = LocalAnalyticsTracker()

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases) { tab in
                NavigationStack {
                    if tab == .dashboard {
                        DashboardView()
                    } else if tab == .friends {
                        FriendsView(
                            incomingInviteURL: incomingInviteURL,
                            onInviteHandled: { incomingInviteURL = nil }
                        )
                    } else if tab == .duels {
                        DuelsView(onFindFriends: { selectedTab = .friends })
                    } else {
                        FeaturePlaceholderView(tab: tab)
                    }
                }
                .tabItem {
                    Label(tab.title, systemImage: tab.systemImage)
                }
                .tag(tab)
            }
            .onOpenURL { url in
                incomingInviteURL = url
                selectedTab = .friends
            }
        }
        .onChange(of: selectedTab, initial: true) { _, tab in
            analytics.track(tab.analyticsEvent)
        }
    }
}

private struct FeaturePlaceholderView: View {
    @Environment(\.colorScheme) private var colorScheme

    let tab: AppTab

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PocketMonkSpacing.large) {
                PocketMonkStatusPill(title: "Foundation", color: PocketMonkColors.jade)

                VStack(alignment: .leading, spacing: PocketMonkSpacing.small) {
                    Text(tab.sectionTitle)
                        .font(.largeTitle.bold())
                        .foregroundStyle(.primary)
                    Text(tab.placeholderDescription)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                PocketMonkCard {
                    PocketMonkListRow(
                        title: "Coming in a later phase",
                        detail: "This space is ready for the next part of your practice.",
                        systemImage: tab.systemImage
                    )
                }
            }
            .padding(PocketMonkSpacing.large)
            .frame(maxWidth: 640, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .background(PocketMonkColors.canvas.color(for: colorScheme))
        .navigationTitle(tab.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct AppFlowPlaceholderView: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(spacing: PocketMonkSpacing.large) {
            ProgressView()
                .tint(PocketMonkColors.jade.light.color)
                .accessibilityLabel("Loading")
            Text(title)
                .font(.title2.bold())
            Text(detail)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(PocketMonkSpacing.tripleExtraLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PocketMonkColors.canvas.color(for: colorScheme))
    }

    @Environment(\.colorScheme) private var colorScheme
}

#Preview("Root tabs") {
    RootView(initialState: .ready)
        .modelContainer(for: [FriendRecord.self, DuelRecord.self, DuelPointAccount.self])
}

#Preview("Onboarding shell") {
    RootView(initialState: .onboarding)
}
