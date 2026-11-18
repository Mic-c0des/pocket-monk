import Foundation

enum DuelCreationStep: Int, CaseIterable, Identifiable, Sendable {
    case opponent
    case duration
    case stake
    case review

    var id: Int { rawValue }

    var number: Int { rawValue + 1 }

    var next: DuelCreationStep? {
        DuelCreationStep(rawValue: rawValue + 1)
    }

    var previous: DuelCreationStep? {
        DuelCreationStep(rawValue: rawValue - 1)
    }

    var isFinal: Bool {
        next == nil
    }

    var title: String {
        switch self {
        case .opponent: "Choose a rival"
        case .duration: "Pick a duration"
        case .stake: "Set the stake"
        case .review: "Review your challenge"
        }
    }

    var subtitle: String {
        switch self {
        case .opponent: "Who’s your monk facing?"
        case .duration: "The timer starts when your rival accepts."
        case .stake: "Keep it friendly. Stakes are just for fun."
        case .review: "Make sure everything looks right before you send it."
        }
    }
}
