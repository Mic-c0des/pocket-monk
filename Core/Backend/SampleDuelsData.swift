import Foundation

enum SampleDuelsData {
    static let incomingChallengeID = sampleID(1)
    static let finishedDuelID = sampleID(2)

    static let tryItHint =
        "This build uses sample duels. Sage has challenged you; accept to start the timer. Challenges you send stay pending until account services are connected."

    static let myScreenTime = DuelScreenTime(baselineMinutes: 240, averageDailyMinutes: 150)

    static func initialDuels(relativeTo date: Date) -> [Duel] {
        [
            Duel(
                id: incomingChallengeID,
                rival: SampleFriendsData.sage,
                initiator: .rival,
                duration: .oneWeek,
                stake: .coffee,
                createdAt: date.addingTimeInterval(-2 * 3_600)
            ),
            Duel(
                id: finishedDuelID,
                rival: SampleFriendsData.sage,
                initiator: .me,
                duration: .oneDay,
                stake: .braggingRights,
                createdAt: date.addingTimeInterval(-6 * 86_400),
                startedAt: date.addingTimeInterval(-5 * 86_400)
            ),
        ]
    }

    static func progress(against rival: FriendProfile, updatedAt date: Date) -> DuelProgress {
        DuelProgress(
            me: myScreenTime,
            rival: rivalScreenTime[rival.username] ?? fallbackRivalScreenTime,
            updatedAt: date
        )
    }

    // A mix of rivals who are ahead of, behind, and close to the current user.
    private static let rivalScreenTime: [String: DuelScreenTime] = [
        SampleFriendsData.sage.username: DuelScreenTime(baselineMinutes: 200, averageDailyMinutes: 150),
        SampleFriendsData.juniper.username: DuelScreenTime(baselineMinutes: 300, averageDailyMinutes: 180),
        SampleFriendsData.river.username: DuelScreenTime(baselineMinutes: 180, averageDailyMinutes: 170),
        SampleFriendsData.kai.username: DuelScreenTime(baselineMinutes: 220, averageDailyMinutes: 230),
        SampleFriendsData.noor.username: DuelScreenTime(baselineMinutes: 160, averageDailyMinutes: 80),
    ]

    private static let fallbackRivalScreenTime = DuelScreenTime(baselineMinutes: 210, averageDailyMinutes: 190)

    // Stable IDs so saved duels still match the samples after relaunch.
    private static func sampleID(_ index: UInt8) -> UUID {
        UUID(uuid: (0x5A, 0x4D, 0xD0, 0, 0, 0, 0x40, 0, 0x80, 0, 0, 0, 0, 0, 0, index))
    }
}
