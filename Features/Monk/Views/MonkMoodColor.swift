import SwiftUI

extension MonkMood {
    var colorToken: AdaptiveColorToken {
        switch self {
        case .superZen, .calm:
            PocketMonkColors.jade
        case .neutral:
            PocketMonkColors.stone
        case .agitated, .distressed:
            PocketMonkColors.ember
        }
    }
}
