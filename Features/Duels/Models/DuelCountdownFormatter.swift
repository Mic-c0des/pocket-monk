import Foundation

enum DuelCountdownFormatter {
    static let expiredText = "Time’s up"

    /// "3d 4h", "4h 12m", "12m 05s" or "9s", showing the two largest units.
    static func compact(_ remaining: TimeInterval) -> String {
        guard remaining > 0 else { return expiredText }
        let parts = Parts(remaining)

        if parts.days > 0 {
            return "\(parts.days)d \(parts.hours)h"
        }
        if parts.hours > 0 {
            return "\(parts.hours)h \(parts.minutes)m"
        }
        if parts.minutes > 0 {
            let seconds = parts.seconds < 10 ? "0\(parts.seconds)" : "\(parts.seconds)"
            return "\(parts.minutes)m \(seconds)s"
        }
        return "\(parts.seconds)s"
    }

    /// Full words for VoiceOver, such as "3 days, 4 hours left".
    static func spoken(_ remaining: TimeInterval) -> String {
        guard remaining > 0 else { return expiredText }
        let parts = Parts(remaining)

        let units: [(value: Int, unit: String)]
        if parts.days > 0 {
            units = [(parts.days, "day"), (parts.hours, "hour")]
        } else if parts.hours > 0 {
            units = [(parts.hours, "hour"), (parts.minutes, "minute")]
        } else if parts.minutes > 0 {
            units = [(parts.minutes, "minute"), (parts.seconds, "second")]
        } else {
            units = [(parts.seconds, "second")]
        }

        let phrase = units
            .filter { $0.value > 0 }
            .map { "\($0.value) \($0.unit)\($0.value == 1 ? "" : "s")" }
            .joined(separator: ", ")
        return "\(phrase) left"
    }

    private struct Parts {
        let days: Int
        let hours: Int
        let minutes: Int
        let seconds: Int

        init(_ remaining: TimeInterval) {
            // Round up so the countdown never reads zero while time is left.
            let total = Int(remaining.rounded(.up))
            days = total / 86_400
            hours = total % 86_400 / 3_600
            minutes = total % 3_600 / 60
            seconds = total % 60
        }
    }
}
