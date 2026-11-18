import Foundation

struct LiveActivityPresentation: Equatable {
    let title: String
    let detail: String
    let actionTitle: String?
    let isActionEnabled: Bool

    static func make(isAvailable: Bool, isActive: Bool) -> LiveActivityPresentation {
        guard isAvailable else {
            return LiveActivityPresentation(
                title: "Live Activity unavailable",
                detail: "Allow Live Activities in Settings to keep your monk on the Lock Screen.",
                actionTitle: nil,
                isActionEnabled: false
            )
        }

        return LiveActivityPresentation(
            title: isActive ? "Monk on your Lock Screen" : "Keep your monk close",
            detail: isActive
                ? "Your monk’s status is visible outside the app."
                : "Show your monk’s current mood on the Lock Screen.",
            actionTitle: isActive ? "End Activity" : "Start Live Activity",
            isActionEnabled: true
        )
    }
}
