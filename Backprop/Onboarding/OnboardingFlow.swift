import SwiftUI

enum OnboardingAnswers {
    static let completedKey = "onboarding.completed"
    static let goalKey = "onboarding.goal"
    static let levelKey = "onboarding.level"
    static let dailyMinutesKey = "onboarding.dailyMinutes"

    static let goals = ["Switch into an ML career", "Understand AI at work", "Ace a course or exam", "Pure curiosity"]
    static let levels = ["Brand new", "Some stats or coding", "I've trained a model"]
    static let dailyMinutes = [5, 10, 15]

    /// Beginners start with stats; everyone else starts with classic ML.
    static func preferredTrackID(level: String) -> String {
        level == levels[0] || level.isEmpty ? "data-foundations" : "classic-ml"
    }
}

/// Welcome → three intro pages → goal → level → daily time → personalized plan → paywall (dismissible).
struct OnboardingFlow: View {
    let onFinish: () -> Void

    @AppStorage(OnboardingAnswers.goalKey) private var goal = ""
    @AppStorage(OnboardingAnswers.levelKey) private var level = ""
    @AppStorage(OnboardingAnswers.dailyMinutesKey) private var dailyMinutes = 5
    @State private var page = 0
    @State private var showPaywall = false

    private static let introCount = IntroFeature.all.count
    private static let pageCount = 5 + introCount
    private static let goalIcons = ["briefcase.fill", "building.2.fill", "graduationcap.fill", "sparkles"]
    private static let levelIcons = ["leaf.fill", "chart.bar.fill", "cpu.fill"]
    private static let timeIcons = ["cup.and.saucer.fill", "figure.walk", "book.fill"]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if page > 0 {
                    Button {
                        withAnimation(Theme.spring) { page -= 1 }
                    } label: {
                        Image(systemName: "chevron.left").font(.headline)
                    }
                    .accessibilityLabel("Back")
                }
                Spacer()
                PageDots(count: Self.pageCount, current: page)
                Spacer()
                // Balances the back button so the dots stay centered.
                Image(systemName: "chevron.left").font(.headline).hidden()
            }
            .frame(height: 44)
            .padding(.horizontal, Theme.padding)

            Group {
                switch page {
                case 0:
                    WelcomePage { advance() }
                case 1...Self.introCount:
                    FeaturePage(feature: IntroFeature.all[page - 1]) { advance() }
                case Self.introCount + 1:
                    ChoicePage(
                        title: "What brings you here?",
                        options: OnboardingAnswers.goals,
                        icons: Self.goalIcons,
                        selection: $goal
                    ) { advance() }
                case Self.introCount + 2:
                    ChoicePage(
                        title: "How much ML do you know?",
                        options: OnboardingAnswers.levels,
                        icons: Self.levelIcons,
                        selection: $level
                    ) { advance() }
                case Self.introCount + 3:
                    ChoicePage(
                        title: "How much time per day?",
                        options: OnboardingAnswers.dailyMinutes.map { "\($0) minutes" },
                        icons: Self.timeIcons,
                        selection: Binding(
                            get: { "\(dailyMinutes) minutes" },
                            set: { dailyMinutes = Int($0.split(separator: " ").first ?? "") ?? 5 }
                        )
                    ) { advance() }
                default:
                    PlanPage(goal: goal, level: level, dailyMinutes: dailyMinutes) { showPaywall = true }
                }
            }
            .id(page)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .padding(.horizontal, Theme.padding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .screenBackground()
        .sheet(isPresented: $showPaywall, onDismiss: onFinish) {
            PaywallSheet()
        }
    }

    private func advance() {
        withAnimation(Theme.spring) { page = min(page + 1, Self.pageCount - 1) }
    }
}

private struct PageDots: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: index == current ? 18 : 6, height: 6)
            }
        }
        .animation(Theme.spring, value: current)
        .accessibilityElement()
        .accessibilityLabel("Step \(current + 1) of \(count)")
    }
}

private struct WelcomePage: View {
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            BackpropMark(size: 120, animated: true)
                .padding(28)
                .cardSurface(cornerRadius: 40)
                .appearAnimation()
            VStack(spacing: 10) {
                Text("Backprop")
                    .font(.largeTitle.bold())
                Text("Understand machine learning,\none 5‑minute lesson at a time.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .appearAnimation(delay: 0.1)
            Spacer()
            Button(action: onStart) {
                Text("Get started").font(.headline).frame(maxWidth: .infinity)
            }
            .primaryButtonStyle()
            .appearAnimation(delay: 0.2)
            .padding(.bottom, 12)
        }
    }
}

/// One intro page about what the app does, shown before the setup questions.
struct IntroFeature {
    let icon: String
    let title: String
    let detail: String

    static let all: [IntroFeature] = [
        IntroFeature(
            icon: "timer",
            title: "Five minutes a lesson",
            detail: "Short, focused steps from statistics to transformers, with a quick check after each idea."
        ),
        IntroFeature(
            icon: "hand.draw.fill",
            title: "Learn by doing",
            detail: "Drag data points, tune learning rates and watch a model learn in real time."
        ),
        IntroFeature(
            icon: "books.vertical.fill",
            title: "Keep going, go deeper",
            detail: "Streaks and XP build the habit. A hand-picked library of free books, papers and videos takes you further."
        ),
    ]
}

private struct FeaturePage: View {
    let feature: IntroFeature
    let onNext: () -> Void

    @State private var animate = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: feature.icon)
                .font(.system(size: 64, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .symbolEffect(.bounce, value: animate)
                .frame(width: 150, height: 150)
                .cardSurface(cornerRadius: 40)
                .appearAnimation()
                .accessibilityHidden(true)
            VStack(spacing: 10) {
                Text(feature.title)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                Text(feature.detail)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .appearAnimation(delay: 0.1)
            Spacer()
            Button(action: onNext) {
                Text("Continue").font(.headline).frame(maxWidth: .infinity)
            }
            .primaryButtonStyle()
            .appearAnimation(delay: 0.2)
            .padding(.bottom, 12)
        }
        .task {
            try? await Task.sleep(for: .milliseconds(400))
            animate = true
        }
    }
}

private struct ChoicePage: View {
    let title: String
    let options: [String]
    let icons: [String]
    @Binding var selection: String
    let onNext: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.largeTitle.bold())
                .padding(.top, 16)
                .padding(.bottom, 12)
            ForEach(Array(options.enumerated()), id: \.element) { index, option in
                Button {
                    selection = option
                    onNext()
                } label: {
                    HStack(spacing: 14) {
                        IconTile(systemImage: index < icons.count ? icons[index] : "circle", size: 40)
                        Text(option).font(.headline).foregroundStyle(.primary)
                        Spacer()
                        if selection == option {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.accentColor)
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .cardSurface(cornerRadius: Theme.smallCornerRadius + 4, interactive: true)
                .appearAnimation(delay: 0.05 * Double(index))
            }
            Spacer()
        }
        .sensoryFeedback(.selection, trigger: selection)
    }
}

private struct PlanPage: View {
    let goal: String
    let level: String
    let dailyMinutes: Int
    let onContinue: () -> Void

    private var startTrack: String {
        OnboardingAnswers.preferredTrackID(level: level) == "data-foundations" ? "Data foundations" : "Classic ML"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your plan is ready")
                .font(.largeTitle.bold())
                .padding(.top, 16)
            VStack(alignment: .leading, spacing: 0) {
                planRow("flag.fill", "Start with \(startTrack)", tint: .accentColor)
                Divider().padding(.leading, 62)
                planRow("clock.fill", "\(dailyMinutes) minutes a day", tint: .accentColor)
                Divider().padding(.leading, 62)
                planRow("hand.draw.fill", "Interactive sims in every track", tint: .accentColor)
                if !goal.isEmpty {
                    Divider().padding(.leading, 62)
                    planRow("target", goal, tint: .accentColor)
                }
            }
            .cardSurface()
            .appearAnimation(delay: 0.05)
            Spacer()
            Button(action: onContinue) {
                Text("Continue").font(.headline).frame(maxWidth: .infinity)
            }
            .primaryButtonStyle()
            .padding(.bottom, 12)
        }
    }

    private func planRow(_ icon: String, _ text: String, tint: Color) -> some View {
        HStack(spacing: 14) {
            IconTile(systemImage: icon, tint: tint, size: 34)
            Text(text).font(.body.weight(.medium))
            Spacer()
        }
        .padding(.horizontal, Theme.padding)
        .padding(.vertical, 12)
    }
}
