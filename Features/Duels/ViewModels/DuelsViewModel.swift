import Combine
import Foundation

@MainActor
final class DuelsViewModel: ObservableObject {
    @Published private(set) var state: DuelsViewState = .loading
    /// Nil until the friend list has loaded.
    @Published private(set) var friends: [Friendship]?
    @Published private(set) var friendsErrorMessage: String?
    @Published private(set) var scoreboards: [UUID: DuelScoreboardState] = [:]
    @Published private(set) var processingDuelIDs: Set<UUID> = []
    @Published private(set) var isCreatingDuel = false
    @Published private(set) var createDuelErrorMessage: String?
    @Published private(set) var actionErrorMessage: String?

    let currentUser: FriendProfile

    private let service: any DuelsServicing
    private let friendsService: any FriendsServicing
    private let reminders: any DuelReminderScheduling
    private let scoreCalculator: ZenScoreCalculator
    private let now: () -> Date

    /// Share `friendsService` with the Friends tab so the rival list stays current.
    init(
        service: (any DuelsServicing)? = nil,
        friendsService: (any FriendsServicing)? = nil,
        reminders: (any DuelReminderScheduling)? = nil,
        currentUser: FriendProfile = SampleFriendsData.guest,
        scoreCalculator: ZenScoreCalculator = ZenScoreCalculator(),
        now: @escaping () -> Date = { .now }
    ) {
        let friendsService = friendsService ?? LocalFriendsService(currentUser: currentUser, now: now)
        self.friendsService = friendsService
        self.service = service ?? LocalDuelsService(
            currentUser: currentUser,
            friendsService: friendsService,
            now: now
        )
        self.reminders = reminders ?? UserNotificationDuelReminderScheduler()
        self.currentUser = currentUser
        self.scoreCalculator = scoreCalculator
        self.now = now
    }

    var book: DuelBook? {
        if case let .loaded(book) = state { book } else { nil }
    }

    func busyRivalIDs(at date: Date) -> Set<UUID> {
        book?.busyRivalIDs(at: date) ?? []
    }

    func isProcessing(_ duelID: UUID) -> Bool {
        processingDuelIDs.contains(duelID)
    }

    func scoreboard(for duelID: UUID) -> DuelScoreboardState? {
        scoreboards[duelID]
    }

    func load() async {
        // Refreshing keeps the current list on screen instead of flashing a spinner.
        let hasLoaded = book != nil
        if !hasLoaded {
            state = .loading
        }

        do {
            try Task.checkCancellation()
            let duels = try await service.loadDuels()
            try Task.checkCancellation()
            show(duels)
        } catch is CancellationError {
            return
        } catch {
            if hasLoaded {
                actionErrorMessage = error.localizedDescription
            } else {
                state = .failed(error.localizedDescription)
            }
        }

        await refreshFriends()
        await scheduleRemindersForActiveDuels()
    }

    func refreshFriends() async {
        do {
            let friendships = try await friendsService.loadFriendships()
            friends = FriendGraph(friendships: friendships).friends
            friendsErrorMessage = nil
        } catch {
            friendsErrorMessage = error.localizedDescription
        }
    }

    /// Returns true when the challenge was sent.
    func createDuel(from draft: DuelDraft) async -> Bool {
        guard !isCreatingDuel else { return false }

        isCreatingDuel = true
        createDuelErrorMessage = nil
        defer { isCreatingDuel = false }

        do {
            let request = try draft.makeRequest(busyRivalIDs: busyRivalIDs(at: now()))
            show(try await service.createDuel(request))
            return true
        } catch {
            createDuelErrorMessage = error.localizedDescription
            return false
        }
    }

    func clearCreateDuelError() {
        createDuelErrorMessage = nil
    }

    func dismissActionError() {
        actionErrorMessage = nil
    }

    func acceptDuel(_ duelID: UUID) async {
        await perform(on: duelID) {
            try await self.service.acceptDuel(duelID)
        }
        guard let duel = book?.duel(with: duelID), !duel.isPending else { return }
        await reminders.scheduleEndReminder(for: duel, at: now())
    }

    func declineDuel(_ duelID: UUID) async {
        await perform(on: duelID) {
            try await self.service.declineDuel(duelID)
        }
    }

    func cancelDuel(_ duelID: UUID) async {
        await perform(on: duelID) {
            try await self.service.cancelDuel(duelID)
        }
    }

    /// Loads the live monk-vs-monk standing. Pending duels have nothing to compare yet.
    func loadScoreboard(for duel: Duel) async {
        guard !duel.isPending else { return }
        let existing = scoreboards[duel.id]
        if existing == nil {
            scoreboards[duel.id] = .loading
        }

        do {
            let progress = try await service.loadProgress(for: duel)
            scoreboards[duel.id] = .loaded(
                try DuelScoreboard.make(
                    progress: progress,
                    me: currentUser,
                    rival: duel.rival,
                    calculator: scoreCalculator
                )
            )
        } catch is CancellationError {
            return
        } catch {
            // Keep the last good standing on screen if a refresh fails.
            if case .loaded = existing { return }
            scoreboards[duel.id] = .failed(error.localizedDescription)
        }
    }

    private func perform(on duelID: UUID, _ operation: () async throws -> [Duel]) async {
        guard !processingDuelIDs.contains(duelID) else { return }

        processingDuelIDs.insert(duelID)
        actionErrorMessage = nil
        defer { processingDuelIDs.remove(duelID) }

        do {
            show(try await operation())
        } catch {
            actionErrorMessage = error.localizedDescription
        }
    }

    private func show(_ duels: [Duel]) {
        state = .loaded(DuelBook(duels: duels))
    }

    private func scheduleRemindersForActiveDuels() async {
        guard let book else { return }
        let date = now()
        for duel in book.activeDuels(at: date) {
            await reminders.scheduleEndReminder(for: duel, at: date)
        }
    }
}
