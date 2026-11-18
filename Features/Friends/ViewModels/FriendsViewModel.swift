import Combine
import Foundation
import SwiftData

@MainActor
final class FriendsViewModel: ObservableObject {
    @Published private(set) var friendRecords: [FriendRecord] = []
    @Published private(set) var inviteURL: URL?
    @Published private(set) var errorMessage: String?
    @Published private(set) var confirmationMessage: String?
    @Published private(set) var hasLoaded = false

    private var service: (any FriendServicing)?

    init(service: (any FriendServicing)? = nil) {
        self.service = service
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
        guard let service else {
            errorMessage = FriendServiceError.serviceNotReady.localizedDescription
            hasLoaded = true
            return
        }
        do {
            friendRecords = try service.loadFriends()
            inviteURL = try service.createInviteLink(now: .now)
            hasLoaded = true
        } catch {
            errorMessage = error.localizedDescription
            hasLoaded = true
        }
    }

    @discardableResult
    func addByUsername(_ username: String) -> Bool {
        perform { service in
            let friend = try service.addByUsername(username, now: .now)
            return "Request sent to @\(friend.username). This is a local demo request."
        }
    }

    @discardableResult
    func addByInviteLink(_ url: URL) -> Bool {
        perform { service in
            let friend = try service.addByInviteLink(url, now: .now)
            return "Invite accepted. A local request to @\(friend.username) was added."
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
        perform { service in
            let request = try service.createDemoIncomingRequest(now: .now)
            return "@\(request.username) sent a demo request."
        }
    }

    @discardableResult
    func acceptRequest(id: UUID) -> Bool {
        perform { service in
            try service.acceptIncomingRequest(id: id, now: .now)
            return "You’re now friends."
        }
    }

    @discardableResult
    func declineRequest(id: UUID) -> Bool {
        perform { service in
            try service.declineIncomingRequest(id: id, now: .now)
            return "Request declined."
        }
    }

    private func perform(
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
            friendRecords = try service.loadFriends()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
