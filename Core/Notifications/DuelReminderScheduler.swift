import Foundation
import UserNotifications

@MainActor
protocol DuelReminderScheduling {
    /// Best effort: a reminder that can't be scheduled never blocks or fails a duel action.
    func scheduleEndReminder(for duel: Duel, at date: Date) async
}

@MainActor
final class UserNotificationDuelReminderScheduler: DuelReminderScheduling {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func scheduleEndReminder(for duel: Duel, at date: Date) async {
        guard let reminder = DuelReminder.endOfDuel(duel, at: date) else { return }
        let center = UNUserNotificationCenter.current()

        do {
            // Provisional authorization delivers quietly to Notification Center without a permission prompt.
            guard try await center.requestAuthorization(options: [.alert, .sound, .provisional]) else {
                return
            }

            let content = UNMutableNotificationContent()
            content.title = reminder.title
            content.body = reminder.body
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: calendar.dateComponents(
                    [.year, .month, .day, .hour, .minute, .second],
                    from: reminder.fireDate
                ),
                repeats: false
            )
            // Reusing the identifier replaces any earlier reminder for the same duel.
            try await center.add(
                UNNotificationRequest(identifier: reminder.identifier, content: content, trigger: trigger)
            )
        } catch {
            // The duel itself is unaffected; the user can still check the Duels tab.
        }
    }
}
