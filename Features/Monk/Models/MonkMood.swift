import Foundation

enum MonkMood: String, CaseIterable, Codable, Sendable {
    case superZen
    case calm
    case neutral
    case agitated
    case distressed

    static func from(zenScore: Int) -> MonkMood {
        switch min(max(zenScore, 0), 100) {
        case 85...:
            .superZen
        case 70..<85:
            .calm
        case 45..<70:
            .neutral
        case 25..<45:
            .agitated
        default:
            .distressed
        }
    }

    var title: String {
        switch self {
        case .superZen: String(localized: "Super zen")
        case .calm: String(localized: "Calm")
        case .neutral: String(localized: "Finding balance")
        case .agitated: String(localized: "A little restless")
        case .distressed: String(localized: "Needs a breather")
        }
    }

    var message: String {
        switch self {
        case .superZen: String(localized: "Your monk is feeling wonderfully balanced.")
        case .calm: String(localized: "A gentler day is helping your monk settle in.")
        case .neutral: String(localized: "Your monk is holding steady today.")
        case .agitated: String(localized: "More screen time than usual is making your monk restless.")
        case .distressed: String(localized: "Your monk could use a quieter moment away from the screen.")
        }
    }

    var systemImage: String {
        switch self {
        case .superZen: "sparkles"
        case .calm: "leaf"
        case .neutral: "circle.dotted"
        case .agitated: "waveform.path.ecg"
        case .distressed: "cloud.bolt"
        }
    }
}
