import Charts
import SwiftUI

/// A ball rolling down L(w) = (w - 3)^2 + 1. Large learning rates overshoot and diverge.
struct GradientDescentPlayground: View {
    private static let domain: ClosedRange<Double> = -6...12
    private static let curve: [Point2D] = stride(from: domain.lowerBound, through: domain.upperBound, by: 0.25)
        .map { Point2D(x: $0, y: ($0 - 3) * ($0 - 3) + 1) }

    @State private var learningRate = 0.1
    @State private var model = GradientDescent1D()
    @State private var trail: [Point2D] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Chart {
                ForEach(Self.curve, id: \.x) { p in
                    LineMark(x: .value("w", p.x), y: .value("loss", p.y))
                        .foregroundStyle(.secondary)
                }
                ForEach(Array(trail.enumerated()), id: \.offset) { _, p in
                    PointMark(x: .value("w", p.x), y: .value("loss", p.y))
                        .foregroundStyle(.orange.opacity(0.4))
                        .symbolSize(40)
                }
                if !model.hasDiverged, Self.domain.contains(model.w) {
                    PointMark(x: .value("w", model.w), y: .value("loss", model.currentLoss))
                        .foregroundStyle(.orange)
                        .symbolSize(200)
                }
            }
            .chartXScale(domain: Self.domain)
            .chartYScale(domain: 0...90)
            .frame(height: 240)
            .accessibilityLabel("Loss curve with the current weight marked")

            VStack(alignment: .leading) {
                Text("Learning rate: \(learningRate, format: .number.precision(.fractionLength(2)))")
                Slider(value: $learningRate, in: 0.01...1.1, step: 0.01)
                    .onChange(of: learningRate) { _, newValue in model.learningRate = newValue }
            }

            Group {
                if model.hasDiverged || !Self.domain.contains(model.w) {
                    Text("Diverged: the steps overshoot further each time. Try a smaller learning rate.")
                        .foregroundStyle(.red)
                } else {
                    Text("Step \(model.steps) · w = \(model.w, format: .number.precision(.fractionLength(3))) · loss = \(model.currentLoss, format: .number.precision(.fractionLength(3)))")
                        .monospacedDigit()
                }
            }
            .font(.callout)

            HStack {
                Button("Step") { step(times: 1) }
                Button("Run 10") { step(times: 10) }
                Spacer()
                Button("Reset", role: .destructive) { reset() }
            }
            .buttonStyle(.bordered)
        }
    }

    private func step(times: Int) {
        for _ in 0..<times {
            guard !model.hasDiverged else { break }
            trail.append(Point2D(x: model.w, y: model.currentLoss))
            model.step()
        }
        if trail.count > 60 { trail.removeFirst(trail.count - 60) }
    }

    private func reset() {
        model = GradientDescent1D(learningRate: learningRate)
        trail = []
    }
}
