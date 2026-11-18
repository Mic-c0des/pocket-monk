import Combine
import Foundation
import SwiftData

@MainActor
final class FriendsViewModel: ObservableObject {
    @Published private(set) var friendRecords: [FriendRecord] = []
    @Published private(set) var inviteURL: URL?
    @Published private(set) var errorMessage: String?
    @Published private(set) var loadErrorMessage: String?
    @Published private(set) var confirmationMessage: String?
    @Published private(set) var hasLoaded = false

    private var service: (any FriendServicing)?
    private let analytics: any AnalyticsTracking

    init(
        service: (any FriendServicing)? = nil,
        analytics: any AnalyticsTracking = LocalAnalyticsTracker()
    ) {
        self.service = service
        self.analytics = analytics
    }

    var friends: [FriendRecord] {
        friendRecords.filter { $0.status == .friends }
    }

    var incomingRequests: [FriendRecord] {
        friendRecords.filter { $0.status == .pendingIncoming }
    }

    var outgoingRequests: [FriendRecord] {
        friendRecords.filter { $0.status == .pendingOutgoing }
    }

    func load(using modelContext: ModelContext) {
        if service == nil {
            service = LocalFriendService(modelContext: modelContext)
        }
        load()
    }

    func load() {
        errorMessage = nil
        loadErrorMessage = nil
        guard let service else {
            let message = FriendServiceError.serviceNotReady.localizedDescription
            errorMessage = message
            loadErrorMessage = message
            hasLoaded = true
            return
        }
        do {
            friendRecords = try service.loadFriends()
            inviteURL = try service.createInviteLink(now: .now)
            hasLoaded = true
        } catch {
            errorMessage = error.localizedDescription
            loadErrorMessage = error.localizedDescription
            analytics.track(.friendsStoreLoadFailed)
            hasLoaded = true
        }
    }

    @discardableResult
    func addByUsername(_ username: String) -> Bool {
        perform(event: .friendRequestSent) { service in
            let friend = try service.addByUsername(username, now: .now)
            return String(
                localized: "Request sent to @\(friend.username). This is a local demo request."
            )
        }
    }

    @discardableResult
    func addByInviteLink(_ url: URL) -> Bool {
        perform(event: .friendRequestSent) { service in
            let friend = try service.addByInviteLink(url, now: .now)
            return String(
                localized: "Invite accepted. A local request to @\(friend.username) was added."
            )
        }
    }

    @discardableResult
    func addByInviteLink(_ text: String) -> Bool {
        guard let url = URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            errorMessage = FriendServiceError.invalidInviteLink.localizedDescription
            confirmationMessage = nil
            return false
        }
        return addByInviteLink(url)
    }

    @discardableResult
    func createDemoIncomingRequest() -> Bool {
        perform(event: .friendRequestReceived) { service in
            let request = try service.createDemoIncomingRequest(now: .now)
            return String(localized: "@\(request.username) sent a demo request.")
        }
    }

    @discardableResult
    func acceptRequest(id: UUID) -> Bool {
        perform(event: .friendRequestAccepted) { service in
            try service.acceptIncomingRequest(id: id, now: .now)
            return String(localized: "You’re now friends.")
        }
    }

    @discardableResult
    func declineRequest(id: UUID) -> Bool {
        perform(event: .friendRequestDeclined) { service in
            try service.declineIncomingRequest(id: id, now: .now)
            return String(localized: "Request declined.")
        }
    }

    private func perform(
        event: AnalyticsEvent,
        _ action: (any FriendServicing) throws -> String
    ) -> Bool {
        errorMessage = nil
        confirmationMessage = nil
        guard let service else {
            errorMessage = FriendServiceError.serviceNotReady.localizedDescription
            return false
        }
        do {
            confirmationMessage = try action(service)
            analytics.track(event)
            friendRecords = try service.loadFriends()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
