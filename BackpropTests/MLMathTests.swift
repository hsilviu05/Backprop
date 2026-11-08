import XCTest
@testable import Backprop

final class MLMathTests: XCTestCase {
    func testPerfectLine() throws {
        let fit = try XCTUnwrap(LinearFit.fit([.init(x: 0, y: 1), .init(x: 1, y: 3), .init(x: 2, y: 5)]))
        XCTAssertEqual(fit.slope, 2, accuracy: 1e-9)
        XCTAssertEqual(fit.intercept, 1, accuracy: 1e-9)
        XCTAssertEqual(fit.meanSquaredError([.init(x: 0, y: 1)]), 0, accuracy: 1e-9)
    }

    func testFitNeedsTwoDistinctX() {
        XCTAssertNil(LinearFit.fit([]))
        XCTAssertNil(LinearFit.fit([.init(x: 1, y: 1)]))
        XCTAssertNil(LinearFit.fit([.init(x: 2, y: 1), .init(x: 2, y: 5)]))
    }

    func testGradientDescentConvergesForSmallLearningRate() {
        var gd = GradientDescent1D(start: -4, learningRate: 0.1)
        for _ in 0..<200 { gd.step() }
        XCTAssertEqual(gd.w, 3, accuracy: 1e-6)
        XCTAssertFalse(gd.hasDiverged)
    }

    func testGradientDescentDivergesAboveOne() {
        var gd = GradientDescent1D(start: -4, learningRate: 1.1)
        let initialDistance = abs(gd.w - 3)
        for _ in 0..<10 { gd.step() }
        XCTAssertGreaterThan(abs(gd.w - 3), initialDistance)
    }
}
