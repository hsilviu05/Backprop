import SwiftUI
import UIKit

/// The Backprop logo. Uses the "BackpropMark" asset when present, otherwise draws
/// a small three-layer neural network so the app always has a mark.
struct BackpropMark: View {
    var size: CGFloat = 28
    var animated = false

    var body: some View {
        Group {
            if UIImage(named: "BackpropMark") != nil {
                Image("BackpropMark")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color.accentColor)
                    .overlay { if animated { BackpropPulse() } }
            } else {
                NetworkGlyph(animated: animated)
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Backprop logo")
    }
}

/// A dot travelling backwards along the mark's bold path (output → hidden → input),
/// matching the asset's geometry: points in a 100-unit space, viewBox origin (19, 18), size 64.
private struct BackpropPulse: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private static let path: [CGPoint] = [CGPoint(x: 73, y: 50), CGPoint(x: 50, y: 38), CGPoint(x: 27, y: 30)]
    private static let travel = 1.5
    private static let cycle = 4.0

    var body: some View {
        if reduceMotion {
            EmptyView()
        } else {
            TimelineView(.animation(minimumInterval: 1 / 30)) { context in
                GeometryReader { geo in
                    let t = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: Self.cycle)
                    if t < Self.travel {
                        let p = Self.point(at: t / Self.travel)
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: geo.size.width * 0.12, height: geo.size.width * 0.12)
                            .shadow(color: Color.accentColor.opacity(0.6), radius: 3)
                            .position(x: (p.x - 19) / 64 * geo.size.width, y: (p.y - 18) / 64 * geo.size.height)
                    }
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    private static func point(at progress: Double) -> CGPoint {
        let eased = progress * progress * (3 - 2 * progress)
        let scaled = eased * Double(path.count - 1)
        let i = min(Int(scaled), path.count - 2)
        let f = scaled - Double(i)
        let a = path[i], b = path[i + 1]
        return CGPoint(x: a.x + (b.x - a.x) * f, y: a.y + (b.y - a.y) * f)
    }
}

/// 2-3-1 network: nodes and edges in the accent color. When animated, a pulse
/// travels backwards through the edges, a nod to backpropagation.
private struct NetworkGlyph: View {
    let animated: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let layers: [[CGPoint]] = [
        [CGPoint(x: 0.14, y: 0.32), CGPoint(x: 0.14, y: 0.68)],
        [CGPoint(x: 0.5, y: 0.18), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.5, y: 0.82)],
        [CGPoint(x: 0.86, y: 0.5)],
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: !animated || reduceMotion)) { context in
            Canvas { gc, size in
                let phase = animated && !reduceMotion
                    ? context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 2.4) / 2.4
                    : -1
                let scale = { (p: CGPoint) in CGPoint(x: p.x * size.width, y: p.y * size.height) }
                let accent = Color.accentColor
                let lineWidth = max(1, size.width * 0.045)

                for layer in 0..<(Self.layers.count - 1) {
                    // Pulse runs from the output layer back to the input layer.
                    let layerPhase = 1 - Double(layer + 1) / Double(Self.layers.count - 1)
                    let highlight = phase >= 0 && abs(phase - layerPhase) < 0.25
                    for a in Self.layers[layer] {
                        for b in Self.layers[layer + 1] {
                            var path = Path()
                            path.move(to: scale(a))
                            path.addLine(to: scale(b))
                            gc.stroke(path, with: .color(accent.opacity(highlight ? 0.9 : 0.4)), lineWidth: lineWidth)
                        }
                    }
                }
                let radius = size.width * 0.1
                for layer in Self.layers {
                    for node in layer {
                        let c = scale(node)
                        let rect = CGRect(x: c.x - radius, y: c.y - radius, width: radius * 2, height: radius * 2)
                        gc.fill(Path(ellipseIn: rect), with: .color(accent))
                    }
                }
            }
        }
    }
}
