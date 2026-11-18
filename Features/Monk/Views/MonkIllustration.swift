import SwiftUI

struct MonkIllustration: View {
    let accessibilityLabel: String

    private let ink = Color(red: 0.035, green: 0.035, blue: 0.047)
    private let robe = Color(red: 0.741, green: 0.659, blue: 0.980)
    private let skin = Color(red: 0.965, green: 0.690, blue: 0.392)
    private let aura = Color(red: 0.247, green: 0.224, blue: 0.349)

    var body: some View {
        Canvas { context, size in
            let side = min(size.width, size.height)
            context.translateBy(
                x: (size.width - side) / 2,
                y: (size.height - side) / 2
            )
            context.scaleBy(x: side / 200, y: side / 200)

            drawAura(in: &context)
            drawRobe(in: &context)
            drawFace(in: &context)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isImage)
    }

    private func drawAura(in context: inout GraphicsContext) {
        let outerRing = Path(ellipseIn: CGRect(x: 10, y: 10, width: 180, height: 180))
        let innerRing = Path(ellipseIn: CGRect(x: 25, y: 25, width: 150, height: 150))
        context.fill(outerRing, with: .color(ink))
        context.stroke(outerRing, with: .color(aura.opacity(0.65)), lineWidth: 1.2)
        context.stroke(innerRing, with: .color(aura.opacity(0.35)), lineWidth: 1)

        var marks = Path()
        marks.move(to: CGPoint(x: 100, y: 8))
        marks.addLine(to: CGPoint(x: 100, y: 15))
        marks.move(to: CGPoint(x: 8, y: 100))
        marks.addLine(to: CGPoint(x: 15, y: 100))
        context.stroke(
            marks,
            with: .color(Color(red: 0.72, green: 0.64, blue: 0.94)),
            style: StrokeStyle(lineWidth: 1.2, lineCap: .round)
        )
    }

    private func drawRobe(in context: inout GraphicsContext) {
        var robeShape = Path()
        robeShape.move(to: CGPoint(x: 79, y: 87))
        robeShape.addCurve(
            to: CGPoint(x: 49, y: 115),
            control1: CGPoint(x: 62, y: 91),
            control2: CGPoint(x: 55, y: 101)
        )
        robeShape.addLine(to: CGPoint(x: 31, y: 155))
        robeShape.addCurve(
            to: CGPoint(x: 46, y: 174),
            control1: CGPoint(x: 25, y: 166),
            control2: CGPoint(x: 33, y: 174)
        )
        robeShape.addLine(to: CGPoint(x: 154, y: 174))
        robeShape.addCurve(
            to: CGPoint(x: 169, y: 155),
            control1: CGPoint(x: 167, y: 174),
            control2: CGPoint(x: 175, y: 166)
        )
        robeShape.addLine(to: CGPoint(x: 151, y: 115))
        robeShape.addCurve(
            to: CGPoint(x: 121, y: 87),
            control1: CGPoint(x: 145, y: 101),
            control2: CGPoint(x: 138, y: 91)
        )
        robeShape.addCurve(
            to: CGPoint(x: 79, y: 87),
            control1: CGPoint(x: 112, y: 108),
            control2: CGPoint(x: 88, y: 108)
        )
        robeShape.closeSubpath()
        context.fill(robeShape, with: .color(robe))
        context.stroke(
            robeShape,
            with: .color(ink),
            style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
        )

        var robeFolds = Path()
        robeFolds.move(to: CGPoint(x: 100, y: 96))
        robeFolds.addLine(to: CGPoint(x: 100, y: 161))
        robeFolds.move(to: CGPoint(x: 50, y: 119))
        robeFolds.addCurve(
            to: CGPoint(x: 94, y: 151),
            control1: CGPoint(x: 70, y: 126),
            control2: CGPoint(x: 82, y: 140)
        )
        robeFolds.move(to: CGPoint(x: 150, y: 119))
        robeFolds.addCurve(
            to: CGPoint(x: 106, y: 151),
            control1: CGPoint(x: 130, y: 126),
            control2: CGPoint(x: 118, y: 140)
        )
        robeFolds.move(to: CGPoint(x: 39, y: 158))
        robeFolds.addCurve(
            to: CGPoint(x: 100, y: 172),
            control1: CGPoint(x: 67, y: 153),
            control2: CGPoint(x: 83, y: 160)
        )
        robeFolds.addCurve(
            to: CGPoint(x: 161, y: 158),
            control1: CGPoint(x: 117, y: 160),
            control2: CGPoint(x: 133, y: 153)
        )
        context.stroke(
            robeFolds,
            with: .color(ink),
            style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
        )
    }

    private func drawFace(in context: inout GraphicsContext) {
        for centerX in [64.0, 136.0] {
            let ear = Path(ellipseIn: CGRect(x: centerX - 10, y: 55, width: 20, height: 23))
            context.fill(ear, with: .color(skin))
            context.stroke(ear, with: .color(ink), lineWidth: 4)
        }

        let head = Path(ellipseIn: CGRect(x: 65, y: 20, width: 70, height: 78))
        context.fill(head, with: .color(skin))
        context.stroke(head, with: .color(ink), lineWidth: 4)

        var features = Path()
        features.move(to: CGPoint(x: 78, y: 48))
        features.addCurve(
            to: CGPoint(x: 96, y: 48),
            control1: CGPoint(x: 83, y: 41),
            control2: CGPoint(x: 91, y: 41)
        )
        features.move(to: CGPoint(x: 104, y: 48))
        features.addCurve(
            to: CGPoint(x: 122, y: 48),
            control1: CGPoint(x: 109, y: 41),
            control2: CGPoint(x: 117, y: 41)
        )
        features.move(to: CGPoint(x: 79, y: 58))
        features.addCurve(
            to: CGPoint(x: 96, y: 58),
            control1: CGPoint(x: 84, y: 66),
            control2: CGPoint(x: 91, y: 66)
        )
        features.move(to: CGPoint(x: 104, y: 58))
        features.addCurve(
            to: CGPoint(x: 121, y: 58),
            control1: CGPoint(x: 109, y: 66),
            control2: CGPoint(x: 116, y: 66)
        )
        features.move(to: CGPoint(x: 87, y: 74))
        features.addCurve(
            to: CGPoint(x: 113, y: 74),
            control1: CGPoint(x: 94, y: 85),
            control2: CGPoint(x: 106, y: 85)
        )
        context.stroke(
            features,
            with: .color(ink),
            style: StrokeStyle(lineWidth: 4.5, lineCap: .round, lineJoin: .round)
        )
    }
}

#Preview {
    MonkIllustration(accessibilityLabel: "Milo, a calm monk meditating")
        .frame(width: 180, height: 180)
        .padding()
        .background(PocketMonkColors.canvas.light.color)
}
