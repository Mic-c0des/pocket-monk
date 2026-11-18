import Foundation

nonisolated struct LiveActivityPresentation: Equatable, Sendable {
    let title: String
    let detail: String
    let actionTitle: String?
    let isActionEnabled: Bool

    static func make(isAvailable: Bool, isActive: Bool) -> LiveActivityPresentation {
        guard isAvailable else {
            return LiveActivityPresentation(
                title: String(localized: "Live Activity unavailable"),
                detail: String(localized: "Allow Live Activities in Settings to keep your monk on the Lock Screen."),
                actionTitle: nil,
                isActionEnabled: false
            )
        }

        return LiveActivityPresentation(
            title: isActive
                ? String(localized: "Monk on your Lock Screen")
                : String(localized: "Keep your monk close"),
            detail: isActive
                ? String(localized: "Your monk’s status is visible outside the app.")
                : String(localized: "Show your monk’s current mood on the Lock Screen."),
            actionTitle: isActive
                ? String(localized: "End Activity")
                : String(localized: "Start Live Activity"),
            isActionEnabled: true
        )
    }
}
