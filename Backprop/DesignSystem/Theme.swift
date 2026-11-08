import SwiftUI

/// Shared look: system fonts, one accent color, glass surfaces on iOS 26+ with a material fallback.
enum Theme {
    static let cornerRadius: CGFloat = 22
    static let smallCornerRadius: CGFloat = 14
    static let padding: CGFloat = 16
    static let spacing: CGFloat = 14

    /// Soft, quick spring used for state changes across the app.
    static let spring = Animation.spring(response: 0.42, dampingFraction: 0.82)

    static func trackTint(_ trackID: String) -> Color {
        switch trackID {
        case "data-foundations": .teal
        case "classic-ml": .indigo
        case "neural-networks": .orange
        case "modern-ai": .pink
        default: .accentColor
        }
    }
}

extension View {
    /// Rounded card surface: liquid glass on iOS 26+, thin material before that.
    @ViewBuilder
    func cardSurface(cornerRadius: CGFloat = Theme.cornerRadius, tint: Color? = nil, interactive: Bool = false) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if #available(iOS 26.0, *) {
            self.glassEffect(
                interactive ? Glass.regular.tint(tint?.opacity(0.12)).interactive() : Glass.regular.tint(tint?.opacity(0.12)),
                in: shape
            )
        } else {
            self
                .background(.regularMaterial, in: shape)
                .overlay(shape.strokeBorder(.white.opacity(0.08)))
        }
    }

    /// Full-width primary call to action.
    @ViewBuilder
    func primaryButtonStyle() -> some View {
        if #available(iOS 26.0, *) {
            self.buttonStyle(.glassProminent).controlSize(.large)
        } else {
            self.buttonStyle(.borderedProminent).controlSize(.large).buttonBorderShape(.capsule)
        }
    }

    @ViewBuilder
    func secondaryButtonStyle() -> some View {
        if #available(iOS 26.0, *) {
            self.buttonStyle(.glass).controlSize(.large)
        } else {
            self.buttonStyle(.bordered).controlSize(.large).buttonBorderShape(.capsule)
        }
    }

    /// Fades and lifts content in once when it first appears. Respects Reduce Motion.
    func appearAnimation(delay: Double = 0) -> some View {
        modifier(AppearModifier(delay: delay))
    }

    /// Soft background used behind scrolling screens.
    func screenBackground(tint: Color = .accentColor) -> some View {
        background {
            LinearGradient(
                colors: [tint.opacity(0.10), Color(.systemGroupedBackground)],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
        }
    }
}

private struct AppearModifier: ViewModifier {
    let delay: Double
    @State private var visible = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .offset(y: visible || reduceMotion ? 0 : 12)
            .onAppear {
                withAnimation(reduceMotion ? .easeOut(duration: 0.2) : Theme.spring.delay(delay)) {
                    visible = true
                }
            }
    }
}

/// Small rounded square holding an SF Symbol, tinted per track.
struct IconTile: View {
    let systemImage: String
    var tint: Color = .accentColor
    var size: CGFloat = 44

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
            .accessibilityHidden(true)
    }
}

/// Circular progress that animates when its value changes.
struct ProgressRing: View {
    let progress: Double
    var tint: Color = .accentColor
    var lineWidth: CGFloat = 5
    var size: CGFloat = 40

    var body: some View {
        ZStack {
            Circle().stroke(tint.opacity(0.18), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(progress, 1)))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(Theme.spring, value: progress)
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel("\(Int((min(progress, 1) * 100).rounded())) percent complete")
    }
}
