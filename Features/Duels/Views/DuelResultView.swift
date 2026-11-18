import CoreFoundation
import CoreGraphics
import CoreTransferable
import ImageIO
import SwiftUI
import UniformTypeIdentifiers

struct DuelResultView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    let duel: DuelRecord
    let pointBalance: Int?

    private let analytics = LocalAnalyticsTracker()

    @State private var shareImage: DuelShareImage?
    @State private var shareError: String?
    @State private var isResultRevealed = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: PocketMonkSpacing.large) {
                    resultContent
                    shareAction
                }
                .padding(PocketMonkSpacing.large)
                .frame(maxWidth: 640, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .top)
            }
            .background(PocketMonkColors.canvas.color(for: colorScheme))
            .navigationTitle("Duel result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                withAnimation(.spring(duration: 0.55, bounce: 0.25)) {
                    isResultRevealed = true
                }
                prepareShareImage()
            }
        }
    }

    @ViewBuilder
    private var resultContent: some View {
        if let winner = duel.winner,
           let userStart = duel.userZenScoreAtStart,
           let userEnd = duel.userZenScoreAtEnd,
           let opponentStart = duel.opponentZenScoreAtStart,
           let opponentEnd = duel.opponentZenScoreAtEnd {
            VStack(alignment: .leading, spacing: PocketMonkSpacing.large) {
                PocketMonkCard {
                    VStack(spacing: PocketMonkSpacing.medium) {
                        Image(systemName: winner.systemImage)
                            .font(.system(size: 42, weight: .semibold))
                            .foregroundStyle(PocketMonkColors.plum.light.color)
                            .symbolEffect(.bounce, value: isResultRevealed)
                            .accessibilityHidden(true)
                        HStack(alignment: .center, spacing: PocketMonkSpacing.medium) {
                            MonkIllustration(accessibilityLabel: "Your monk")
                                .frame(width: 72, height: 72)
                            Text("VS")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            MonkIllustration(
                                accessibilityLabel: "Demo monk for \(duel.opponentUsername)"
                            )
                            .frame(width: 72, height: 72)
                        }
                        .accessibilityElement(children: .combine)
                        Text(winner.title)
                            .font(.largeTitle.bold())
                            .multilineTextAlignment(.center)
                        Text("@\(duel.opponentUsername)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PocketMonkSpacing.medium)
                    .scaleEffect(isResultRevealed ? 1 : 0.92)
                    .opacity(isResultRevealed ? 1 : 0)
                }

                scoreComparison(
                    userStart: userStart,
                    userEnd: userEnd,
                    opponentStart: opponentStart,
                    opponentEnd: opponentEnd
                )
                pointsSummary(for: winner)
            }
        } else {
            PocketMonkCard {
                Label(
                    "This duel result is incomplete.",
                    systemImage: "exclamationmark.triangle"
                )
                .foregroundStyle(PocketMonkColors.ember.color(for: colorScheme))
            }
        }
    }

    private func scoreComparison(
        userStart: Int,
        userEnd: Int,
        opponentStart: Int,
        opponentEnd: Int
    ) -> some View {
        PocketMonkCard {
            VStack(alignment: .leading, spacing: PocketMonkSpacing.medium) {
                PocketMonkSectionLabel(title: "Baseline-normalized zen change")
                scoreRow(
                    title: "You",
                    start: userStart,
                    end: userEnd,
                    change: userEnd - userStart
                )
                Divider()
                scoreRow(
                    title: "@\(duel.opponentUsername) · simulated",
                    start: opponentStart,
                    end: opponentEnd,
                    change: opponentEnd - opponentStart
                )
                Text("The larger improvement from each player’s own baseline wins.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func scoreRow(
        title: String,
        start: Int,
        end: Int,
        change: Int
    ) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: PocketMonkSpacing.extraSmall) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text("Start \(start) → End \(end)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(changeLabel(change))
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(change >= 0
                    ? PocketMonkColors.jade.color(for: colorScheme)
                    : PocketMonkColors.ember.color(for: colorScheme))
                .accessibilityLabel("Zen score change")
                .accessibilityValue(changeLabel(change))
        }
    }

    private func pointsSummary(for winner: DuelWinner) -> some View {
        PocketMonkCard {
            VStack(alignment: .leading, spacing: PocketMonkSpacing.small) {
                PocketMonkSectionLabel(title: "Virtual points")
                Text(pointsOutcome(for: winner))
                    .font(.subheadline.weight(.medium))
                if let pointBalance {
                    Text("Your balance: \(pointBalance) points")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Your balance is unavailable.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var shareAction: some View {
        if let shareImage {
            ShareLink(
                item: shareImage,
                preview: SharePreview("Pocket Monk duel result")
            ) {
                Label("Share result card", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(.borderedProminent)
            .tint(PocketMonkColors.plum.light.color)
        } else if let shareError {
            Label(shareError, systemImage: "exclamationmark.triangle")
                .font(.subheadline)
                .foregroundStyle(PocketMonkColors.ember.color(for: colorScheme))
        } else {
            HStack(spacing: PocketMonkSpacing.small) {
                ProgressView()
                Text("Preparing share card…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .accessibilityElement(children: .combine)
        }
    }

    private func prepareShareImage() {
        guard let winner = duel.winner,
              let userStart = duel.userZenScoreAtStart,
              let userEnd = duel.userZenScoreAtEnd,
              let opponentStart = duel.opponentZenScoreAtStart,
              let opponentEnd = duel.opponentZenScoreAtEnd else {
            shareError = "The result card can’t be created because scores are missing."
            return
        }

        let card = DuelResultShareCard(
            opponentUsername: duel.opponentUsername,
            winnerTitle: winner.title,
            userChange: userEnd - userStart,
            opponentChange: opponentEnd - opponentStart,
            stakePoints: duel.stakePoints
        )
        let renderer = ImageRenderer(content: card)
        renderer.scale = 2
        guard let renderedImage = renderer.cgImage,
              let imageData = pngData(for: renderedImage) else {
            shareError = "The result card couldn’t be rendered."
            return
        }
        shareImage = DuelShareImage(data: imageData)
        analytics.track(.resultCardGenerated)
    }

    private func pngData(for image: CGImage) -> Data? {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data as CFMutableData,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            return nil
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }

    private func changeLabel(_ change: Int) -> String {
        change > 0 ? "+\(change)" : "\(change)"
    }

    private func pointsOutcome(for winner: DuelWinner) -> String {
        guard duel.stakePoints > 0 else {
            return String(localized: "No points were staked.")
        }
        switch winner {
        case .user:
            return String(localized: "You received the \(2 * duel.stakePoints)-point pot.")
        case .opponent:
            return String(localized: "Your stake of \(duel.stakePoints) points went to your friend.")
        case .draw:
            return String(localized: "Both \(duel.stakePoints)-point stakes were returned.")
        }
    }
}

private struct DuelResultShareCard: View {
    let opponentUsername: String
    let winnerTitle: String
    let userChange: Int
    let opponentChange: Int
    let stakePoints: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("POCKET MONK")
                .font(.caption.weight(.bold))
                .tracking(2)
                .foregroundStyle(PocketMonkColors.plum.light.color)
            Text(winnerTitle)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            Text("You vs. @\(opponentUsername)")
                .font(.headline)
                .foregroundStyle(.secondary)
            HStack(spacing: 16) {
                MonkIllustration(accessibilityLabel: "Your monk")
                    .frame(width: 64, height: 64)
                Text("VS")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                MonkIllustration(accessibilityLabel: "Demo monk for \(opponentUsername)")
                    .frame(width: 64, height: 64)
            }
            .frame(maxWidth: .infinity)
            Divider()
            shareScore(title: "Your zen change", value: userChange)
            shareScore(title: "@\(opponentUsername) · simulated", value: opponentChange)
            if stakePoints > 0 {
                Divider()
                Text("Virtual stake: \(stakePoints) points each")
                    .font(.subheadline.weight(.semibold))
            }
            Text("Results compare improvement from each player’s own baseline.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(28)
        .frame(width: 360, alignment: .leading)
        .background(PocketMonkColors.canvas.light.color)
    }

    private func shareScore(title: String, value: Int) -> some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.medium))
            Spacer()
            Text(value > 0 ? "+\(value)" : "\(value)")
                .font(.title3.bold().monospacedDigit())
        }
    }
}

private struct DuelShareImage: Transferable, Sendable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .png) { image in
            image.data
        } importing: { data in
            DuelShareImage(data: data)
        }
    }
}

#Preview("Duel result") {
    DuelResultView(
        duel: DuelRecord(
            opponentUsername: "ava",
            duration: .oneDay,
            durationSeconds: DuelRules.secondsPerDay,
            stakePoints: 10,
            status: .finished,
            createdAt: .now,
            startedAt: .now,
            endsAt: .now,
            userZenScoreAtStart: 65,
            opponentZenScoreAtStart: 70,
            userZenScoreAtEnd: 78,
            opponentZenScoreAtEnd: 72,
            winner: .user,
            resolvedAt: .now
        ),
        pointBalance: 110
    )
}
