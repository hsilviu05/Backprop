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
                    .modifier(MarkEntrance(enabled: animated))
            } else {
                NetworkGlyph(animated: animated)
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Backprop logo")
    }
}

/// Gentle entrance for the mark: fades in and settles from 96% to full size.
private struct MarkEntrance: ViewModifier {
    let enabled: Bool
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if enabled {
            content
                .opacity(shown ? 1 : 0)
                .scaleEffect(shown || reduceMotion ? 1 : 0.96)
                .onAppear {
                    withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .easeOut(duration: 0.6)) { shown = true }
                }
        } else {
            content
        }
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
