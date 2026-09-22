import SwiftUI

/// Vector illustration of an equipment build type, drawn in code so it scales,
/// follows the accent tint and needs no bundled artwork.
struct EquipmentSilhouetteView: View {
    let silhouette: EquipmentSilhouette
    var tint: Color = .accentColor

    var body: some View {
        Canvas { context, size in
            var painter = SilhouettePainter(context: context, size: size, tint: tint)
            painter.draw(silhouette)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

/// Draws in a unit square (0...1) that is scaled to the canvas size.
private struct SilhouettePainter {
    var context: GraphicsContext
    let size: CGSize
    let tint: Color

    private var body: GraphicsContext.Shading { .color(tint) }
    private var light: GraphicsContext.Shading { .color(tint.opacity(0.55)) }
    private var face: GraphicsContext.Shading { .color(Color(.systemBackground).opacity(0.9)) }

    private var scale: CGFloat { min(size.width, size.height) }
    private var offset: CGPoint {
        CGPoint(x: (size.width - scale) / 2, y: (size.height - scale) / 2)
    }

    private func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: offset.x + x * scale, y: offset.y + y * scale)
    }

    private func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
        CGRect(x: offset.x + x * scale, y: offset.y + y * scale, width: w * scale, height: h * scale)
    }

    private mutating func box(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, corner: CGFloat = 0.02, _ shading: GraphicsContext.Shading? = nil) {
        let path = Path(roundedRect: rect(x, y, w, h), cornerRadius: corner * scale, style: .continuous)
        context.fill(path, with: shading ?? body)
    }

    private mutating func circle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ shading: GraphicsContext.Shading? = nil) {
        let path = Path(ellipseIn: rect(cx - r, cy - r, r * 2, r * 2))
        context.fill(path, with: shading ?? body)
    }

    private mutating func polygon(_ points: [(CGFloat, CGFloat)], _ shading: GraphicsContext.Shading? = nil) {
        var path = Path()
        guard let first = points.first else { return }
        path.move(to: point(first.0, first.1))
        for p in points.dropFirst() { path.addLine(to: point(p.0, p.1)) }
        path.closeSubpath()
        context.fill(path, with: shading ?? body)
    }

    private mutating func stroke(from: (CGFloat, CGFloat), to: (CGFloat, CGFloat), width: CGFloat, _ shading: GraphicsContext.Shading? = nil) {
        var path = Path()
        path.move(to: point(from.0, from.1))
        path.addLine(to: point(to.0, to.1))
        context.stroke(path, with: shading ?? body, style: StrokeStyle(lineWidth: width * scale, lineCap: .round))
    }

    private mutating func gauge(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) {
        circle(cx, cy, r, face)
        stroke(from: (cx, cy), to: (cx + r * 0.55, cy - r * 0.35), width: r * 0.28, light)
    }

    private mutating func portafilter(x: CGFloat, y: CGFloat, headWidth: CGFloat = 0.14, handleLength: CGFloat = 0.28) {
        box(x, y, headWidth, 0.07, corner: 0.015, light)
        box(x + headWidth * 0.6, y + 0.02, handleLength, 0.045, corner: 0.02)
    }

    private mutating func steamWand(from: (CGFloat, CGFloat), to: (CGFloat, CGFloat)) {
        stroke(from: from, to: to, width: 0.032, light)
        circle(to.0, to.1, 0.024, light)
    }

    private mutating func hopper(cx: CGFloat, top: CGFloat, bottom: CGFloat, topWidth: CGFloat, bottomWidth: CGFloat) {
        polygon([
            (cx - bottomWidth / 2, bottom),
            (cx + bottomWidth / 2, bottom),
            (cx + topWidth / 2, top),
            (cx - topWidth / 2, top)
        ], light)
        box(cx - topWidth / 2 - 0.02, top - 0.035, topWidth + 0.04, 0.04, corner: 0.015)
    }

    mutating func draw(_ silhouette: EquipmentSilhouette) {
        switch silhouette {
        case .machineE61: drawE61()
        case .machineCompact: drawCompact()
        case .machineCommercial: drawCommercial()
        case .machineLever: drawLever()
        case .machineHome: drawHome()
        case .grinderHopper: drawHopperGrinder()
        case .grinderSingleDose: drawSingleDoseGrinder()
        case .grinderHand: drawHandGrinder()
        case .grinderCommercial: drawCommercialGrinder()
        }
    }

    // MARK: Machines

    private mutating func drawE61() {
        box(0.16, 0.14, 0.68, 0.06, corner: 0.015, light)
        box(0.18, 0.18, 0.64, 0.54, corner: 0.04)
        gauge(0.31, 0.38, 0.075)
        gauge(0.69, 0.38, 0.075)
        box(0.30, 0.52, 0.40, 0.03, corner: 0.01, light)
        steamWand(from: (0.24, 0.72), to: (0.13, 0.90))
        portafilter(x: 0.43, y: 0.70)
        box(0.14, 0.86, 0.72, 0.06, corner: 0.02)
    }

    private mutating func drawCompact() {
        box(0.26, 0.10, 0.48, 0.05, corner: 0.015, light)
        box(0.28, 0.13, 0.44, 0.58, corner: 0.035)
        circle(0.38, 0.30, 0.032, face)
        circle(0.50, 0.30, 0.032, face)
        circle(0.62, 0.30, 0.032, face)
        box(0.36, 0.42, 0.28, 0.03, corner: 0.01, light)
        steamWand(from: (0.70, 0.70), to: (0.83, 0.86))
        portafilter(x: 0.42, y: 0.70, headWidth: 0.13, handleLength: 0.26)
        box(0.24, 0.86, 0.52, 0.06, corner: 0.02)
    }

    private mutating func drawCommercial() {
        box(0.04, 0.24, 0.92, 0.05, corner: 0.015, light)
        box(0.06, 0.27, 0.88, 0.40, corner: 0.04)
        gauge(0.50, 0.44, 0.065)
        box(0.14, 0.34, 0.20, 0.03, corner: 0.01, light)
        box(0.66, 0.34, 0.20, 0.03, corner: 0.01, light)
        steamWand(from: (0.12, 0.66), to: (0.05, 0.85))
        steamWand(from: (0.88, 0.66), to: (0.95, 0.85))
        portafilter(x: 0.24, y: 0.66, headWidth: 0.13, handleLength: 0.16)
        portafilter(x: 0.56, y: 0.66, headWidth: 0.13, handleLength: 0.16)
        box(0.04, 0.86, 0.92, 0.06, corner: 0.02)
    }

    private mutating func drawLever() {
        box(0.20, 0.88, 0.60, 0.06, corner: 0.02)
        box(0.44, 0.28, 0.12, 0.60, corner: 0.02)
        stroke(from: (0.50, 0.30), to: (0.86, 0.10), width: 0.05)
        circle(0.86, 0.10, 0.05)
        box(0.36, 0.50, 0.28, 0.24, corner: 0.05, light)
        box(0.40, 0.58, 0.20, 0.03, corner: 0.01, face)
        portafilter(x: 0.42, y: 0.74, headWidth: 0.16, handleLength: 0.24)
    }

    private mutating func drawHome() {
        hopper(cx: 0.34, top: 0.10, bottom: 0.28, topWidth: 0.20, bottomWidth: 0.16)
        box(0.18, 0.26, 0.64, 0.05, corner: 0.015, light)
        box(0.20, 0.29, 0.60, 0.44, corner: 0.05)
        circle(0.62, 0.48, 0.085, face)
        circle(0.62, 0.48, 0.035, light)
        box(0.28, 0.42, 0.18, 0.03, corner: 0.01, light)
        box(0.28, 0.50, 0.18, 0.03, corner: 0.01, light)
        steamWand(from: (0.78, 0.70), to: (0.90, 0.87))
        portafilter(x: 0.42, y: 0.72, headWidth: 0.14, handleLength: 0.30)
        box(0.16, 0.88, 0.68, 0.06, corner: 0.02)
    }

    // MARK: Grinders

    private mutating func drawHopperGrinder() {
        hopper(cx: 0.50, top: 0.10, bottom: 0.32, topWidth: 0.30, bottomWidth: 0.38)
        box(0.44, 0.31, 0.12, 0.06, corner: 0.01, light)
        box(0.30, 0.36, 0.40, 0.42, corner: 0.05)
        circle(0.50, 0.50, 0.065, face)
        box(0.38, 0.62, 0.24, 0.03, corner: 0.01, light)
        box(0.42, 0.76, 0.16, 0.06, corner: 0.015, light)
        box(0.36, 0.81, 0.28, 0.035, corner: 0.01, light)
        box(0.26, 0.88, 0.48, 0.06, corner: 0.02)
    }

    private mutating func drawSingleDoseGrinder() {
        hopper(cx: 0.50, top: 0.12, bottom: 0.24, topWidth: 0.14, bottomWidth: 0.20)
        box(0.28, 0.23, 0.44, 0.44, corner: 0.10)
        circle(0.50, 0.45, 0.10, face)
        circle(0.50, 0.45, 0.05)
        box(0.44, 0.66, 0.12, 0.06, corner: 0.01, light)
        box(0.40, 0.73, 0.20, 0.15, corner: 0.03, light)
        box(0.26, 0.88, 0.48, 0.06, corner: 0.02)
    }

    private mutating func drawHandGrinder() {
        box(0.36, 0.30, 0.28, 0.58, corner: 0.06)
        box(0.36, 0.62, 0.28, 0.26, corner: 0.06, light)
        box(0.34, 0.26, 0.32, 0.06, corner: 0.02)
        box(0.48, 0.12, 0.04, 0.16, corner: 0.01)
        stroke(from: (0.50, 0.12), to: (0.80, 0.18), width: 0.04)
        circle(0.80, 0.18, 0.05)
        box(0.42, 0.42, 0.16, 0.03, corner: 0.01, face)
    }

    private mutating func drawCommercialGrinder() {
        hopper(cx: 0.50, top: 0.08, bottom: 0.30, topWidth: 0.32, bottomWidth: 0.40)
        box(0.34, 0.29, 0.32, 0.58, corner: 0.03)
        circle(0.50, 0.42, 0.065, face)
        box(0.40, 0.54, 0.20, 0.03, corner: 0.01, light)
        box(0.26, 0.66, 0.12, 0.06, corner: 0.015, light)
        box(0.24, 0.72, 0.16, 0.10, corner: 0.02, light)
        box(0.24, 0.86, 0.52, 0.08, corner: 0.02)
    }
}

#Preview("Silhouettes") {
    ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
            ForEach(EquipmentSilhouette.allCases) { silhouette in
                VStack {
                    EquipmentSilhouetteView(silhouette: silhouette)
                        .frame(width: 100, height: 100)
                        .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
                    Text(silhouette.title).font(.caption)
                }
            }
        }
        .padding()
    }
}
