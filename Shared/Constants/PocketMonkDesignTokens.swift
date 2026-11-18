import SwiftUI

enum PocketMonkSpacing {
    static let extraSmall: CGFloat = 4
    static let small: CGFloat = 8
    static let mediumSmall: CGFloat = 12
    static let medium: CGFloat = 16
    static let mediumLarge: CGFloat = 20
    static let large: CGFloat = 24
    static let extraLarge: CGFloat = 32
    static let doubleExtraLarge: CGFloat = 40
    static let tripleExtraLarge: CGFloat = 48
}

enum PocketMonkCornerRadius {
    static let small: CGFloat = 12
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let extraLarge: CGFloat = 32
}

struct RGBColor: Equatable, Sendable {
    let red: Double
    let green: Double
    let blue: Double

    var color: Color {
        Color(red: red, green: green, blue: blue)
    }
}

struct AdaptiveColorToken: Equatable, Sendable {
    let light: RGBColor
    let dark: RGBColor

    func color(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .light:
            light.color
        case .dark:
            dark.color
        @unknown default:
            light.color
        }
    }
}

enum PocketMonkColors {
    static let canvas = AdaptiveColorToken(
        light: RGBColor(red: 0.969, green: 0.957, blue: 0.925),
        dark: RGBColor(red: 0.090, green: 0.110, blue: 0.098)
    )
    static let surface = AdaptiveColorToken(
        light: RGBColor(red: 1.000, green: 1.000, blue: 1.000),
        dark: RGBColor(red: 0.137, green: 0.161, blue: 0.145)
    )
    static let jade = AdaptiveColorToken(
        light: RGBColor(red: 0.247, green: 0.463, blue: 0.373),
        dark: RGBColor(red: 0.522, green: 0.725, blue: 0.604)
    )
    static let ember = AdaptiveColorToken(
        light: RGBColor(red: 0.725, green: 0.373, blue: 0.275),
        dark: RGBColor(red: 0.910, green: 0.557, blue: 0.424)
    )
    static let plum = AdaptiveColorToken(
        light: RGBColor(red: 0.357, green: 0.294, blue: 0.510),
        dark: RGBColor(red: 0.682, green: 0.616, blue: 0.831)
    )
    static let stone = AdaptiveColorToken(
        light: RGBColor(red: 0.420, green: 0.435, blue: 0.408),
        dark: RGBColor(red: 0.690, green: 0.710, blue: 0.671)
    )
}
