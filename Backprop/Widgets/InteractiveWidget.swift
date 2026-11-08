import SwiftUI

struct InteractiveWidget: View {
    let kind: WidgetKind

    var body: some View {
        Group {
            switch kind {
            case .linearRegression: RegressionPlayground()
            case .gradientDescent: GradientDescentPlayground()
            }
        }
        .padding()
        .cardSurface()
    }
}
