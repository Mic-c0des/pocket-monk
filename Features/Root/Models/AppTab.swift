import Foundation

enum AppTab: String, CaseIterable, Identifiable, Sendable {
    case dashboard
    case friends
    case duels
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: "Home"
        case .friends: "Friends"
        case .duels: "Duels"
        case .settings: "Settings"
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

    var placeholderDescription: String {
        switch self {
        case .dashboard: "Your monk and daily zen summary."
        case .friends: "Add friends and keep each other accountable."
        case .duels: "Create a friendly challenge and find your calm."
        case .settings: "Your account and app preferences will appear here."
        }
    }

    var sectionTitle: String {
        switch self {
        case .dashboard: "Your practice"
        case .friends: "Your circle"
        case .duels: "Friendly challenges"
        case .settings: "Pocket Monk"
        }
    }
}
