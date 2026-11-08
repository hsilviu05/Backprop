import Foundation

struct Point2D: Hashable, Sendable {
    var x: Double
    var y: Double
}

/// Ordinary least squares fit of y = slope * x + intercept.
struct LinearFit: Equatable, Sendable {
    let slope: Double
    let intercept: Double

    /// Nil with fewer than two points or when all x values are equal (vertical line).
    static func fit(_ points: [Point2D]) -> LinearFit? {
        guard points.count >= 2 else { return nil }
        let n = Double(points.count)
        let meanX = points.reduce(0) { $0 + $1.x } / n
        let meanY = points.reduce(0) { $0 + $1.y } / n
        var covariance = 0.0
        var varianceX = 0.0
        for p in points {
            covariance += (p.x - meanX) * (p.y - meanY)
            varianceX += (p.x - meanX) * (p.x - meanX)
        }
        guard varianceX > 1e-12 else { return nil }
        let slope = covariance / varianceX
        return LinearFit(slope: slope, intercept: meanY - slope * meanX)
    }

    func predict(_ x: Double) -> Double { slope * x + intercept }

    func meanSquaredError(_ points: [Point2D]) -> Double {
        guard !points.isEmpty else { return 0 }
        return points.reduce(0) { $0 + pow($1.y - predict($1.x), 2) } / Double(points.count)
    }
}

/// Gradient descent on the 1-D loss L(w) = (w - target)^2 + floor.
struct GradientDescent1D: Equatable, Sendable {
    var target: Double = 3
    var floor: Double = 1
    var w: Double
    var learningRate: Double
    private(set) var steps = 0

    init(start: Double = -4, learningRate: Double = 0.1) {
        self.w = start
        self.learningRate = learningRate
    }

    func loss(at w: Double) -> Double { (w - target) * (w - target) + floor }
    func gradient(at w: Double) -> Double { 2 * (w - target) }

    var currentLoss: Double { loss(at: w) }

    /// Diverged once the weight has blown far away from the minimum or stopped being finite.
    var hasDiverged: Bool { !w.isFinite || abs(w - target) > 1e6 }

    mutating func step() {
        guard !hasDiverged else { return }
        w -= learningRate * gradient(at: w)
        steps += 1
    }
}
