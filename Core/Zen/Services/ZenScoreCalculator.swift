import Foundation

struct ZenScoreCalculator: Sendable {
    func calculate(
        screenTimeMinutes: Int,
        baselineMinutes: Int
    ) throws -> Int {
        guard screenTimeMinutes >= 0 else {
            throw ZenScoreError.negativeScreenTime
        }
        guard baselineMinutes > 0 else {
            throw ZenScoreError.invalidBaseline
        }

        let relativeReduction =
            (Double(baselineMinutes) - Double(screenTimeMinutes)) / Double(baselineMinutes)
        // The baseline maps to 50; a full-baseline reduction reaches 100.
        let normalizedScore = 50 + relativeReduction * 50
        return Int(min(max(normalizedScore, 0), 100).rounded())
    }
}

enum ZenScoreError: LocalizedError, Equatable, Sendable {
    case negativeScreenTime
    case invalidBaseline

    var errorDescription: String? {
        switch self {
        case .negativeScreenTime:
            "Screen time cannot be negative."
        case .invalidBaseline:
            "A positive screen-time baseline is required."
        }
    }
}
