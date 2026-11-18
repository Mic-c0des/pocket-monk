import SwiftUI

struct PocketMonkCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(PocketMonkSpacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PocketMonkColors.surface.color(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: PocketMonkCornerRadius.large))
    }
}
