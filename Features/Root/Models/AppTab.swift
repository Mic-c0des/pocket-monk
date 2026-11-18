import Foundation

enum AppTab: String, CaseIterable, Identifiable, Sendable {
    case dashboard
    case friends
    case duels
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: String(localized: "Home")
        case .friends: String(localized: "Friends")
        case .duels: String(localized: "Duels")
        case .settings: String(localized: "Settings")
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: "leaf"
        case .friends: "person.2"
        case .duels: "figure.martial.arts"
        case .settings: "slider.horizontal.3"
        }
    }

    var analyticsEvent: AnalyticsEvent {
        switch self {
        case .dashboard: .homeViewed
        case .friends: .friendsViewed
        case .duels: .duelsViewed
        case .settings: .settingsViewed
        }
    }

    var placeholderDescription: String {
        switch self {
        case .dashboard: String(localized: "Your monk and daily zen summary.")
        case .friends: String(localized: "Add friends and keep each other accountable.")
        case .duels: String(localized: "Create a friendly challenge and find your calm.")
        case .settings: String(localized: "Your account and app preferences will appear here.")
        }
    }

    var sectionTitle: String {
        switch self {
        case .dashboard: String(localized: "Your practice")
        case .friends: String(localized: "Your circle")
        case .duels: String(localized: "Friendly challenges")
        case .settings: String(localized: "Pocket Monk")
        }
    }
}
