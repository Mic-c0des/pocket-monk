import Foundation

enum FriendsViewState: Equatable, Sendable {
    case loading
    case loaded(FriendGraph)
    case failed(String)
}
