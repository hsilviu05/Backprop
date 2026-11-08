import Charts
import SwiftUI

/// Tap to add a point, drag a point to move it; the least-squares line refits live.
struct RegressionPlayground: View {
    private static let initialPoints: [Point2D] = [
        .init(x: 1, y: 2.1), .init(x: 2, y: 2.9), .init(x: 3, y: 4.2),
        .init(x: 4, y: 4.8), .init(x: 5, y: 6.1), .init(x: 6, y: 6.8),
    ]
    private static let domain: ClosedRange<Double> = 0...10
    private static let maxPoints = 30

    @State private var points = initialPoints
    @State private var draggedIndex: Int?

    private var fit: LinearFit? { LinearFit.fit(points) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Chart {
                ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                    PointMark(x: .value("x", point.x), y: .value("y", point.y))
                        .symbolSize(120)
                }
                if let fit {
                    LineMark(x: .value("x", Self.domain.lowerBound), y: .value("y", fit.predict(Self.domain.lowerBound)))
                    LineMark(x: .value("x", Self.domain.upperBound), y: .value("y", fit.predict(Self.domain.upperBound)))
                }
            }
            .chartXScale(domain: Self.domain)
            .chartYScale(domain: Self.domain)
            .frame(height: 260)
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .gesture(dragGesture(proxy: proxy, geometry: geometry))
                }
            }
            .accessibilityLabel("Scatter plot with \(points.count) points and a fitted line")

            HStack {
                if let fit {
                    Text("y = \(fit.slope, format: .number.precision(.fractionLength(2)))x + \(fit.intercept, format: .number.precision(.fractionLength(2)))")
                    Spacer()
                    Text("MSE \(fit.meanSquaredError(points), format: .number.precision(.fractionLength(2)))")
                } else {
                    Text("Add points with different x values to fit a line.")
                    Spacer()
                }
            }
            .font(.callout.monospacedDigit())

            Button("Reset points") { points = Self.initialPoints }
                .buttonStyle(.bordered)
        }
    }

    private func dragGesture(proxy: ChartProxy, geometry: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard let plotFrame = proxy.plotFrame else { return }
                let frame = geometry[plotFrame]
                let location = CGPoint(x: value.location.x - frame.origin.x, y: value.location.y - frame.origin.y)
                guard let x: Double = proxy.value(atX: location.x),
                      let y: Double = proxy.value(atY: location.y) else { return }
                let clamped = Point2D(x: x.clamped(to: Self.domain), y: y.clamped(to: Self.domain))

                if draggedIndex == nil {
                    draggedIndex = nearestPointIndex(to: value.startLocation, proxy: proxy, origin: frame.origin)
                    if draggedIndex == nil, points.count < Self.maxPoints {
                        points.append(clamped)
                        draggedIndex = points.count - 1
                    }
                }
                if let index = draggedIndex, points.indices.contains(index) {
                    points[index] = clamped
                }
            }
            .onEnded { _ in draggedIndex = nil }
    }

    private func nearestPointIndex(to location: CGPoint, proxy: ChartProxy, origin: CGPoint) -> Int? {
        let hitRadius: CGFloat = 28
        var best: (index: Int, distance: CGFloat)?
        for (index, point) in points.enumerated() {
            guard let px = proxy.position(forX: point.x), let py = proxy.position(forY: point.y) else { continue }
            let distance = hypot(px + origin.x - location.x, py + origin.y - location.y)
            if distance <= hitRadius, distance < (best?.distance ?? .infinity) {
                best = (index, distance)
            }
        }
        return best?.index
    }
}

extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
