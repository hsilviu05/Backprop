import SwiftUI

enum OnboardingAnswers {
    static let completedKey = "onboarding.completed"
    static let goalKey = "onboarding.goal"
    static let levelKey = "onboarding.level"
    static let dailyMinutesKey = "onboarding.dailyMinutes"

    static let goals = ["Switch into an ML career", "Understand AI at work", "Ace a course or exam", "Pure curiosity"]
    static let levels = ["Brand new", "Some stats or coding", "I've trained a model"]
    static let dailyMinutes = [5, 10, 15]
}

/// Goal → level → daily time → personalized plan → paywall (dismissible).
struct OnboardingFlow: View {
    let onFinish: () -> Void

    @AppStorage(OnboardingAnswers.goalKey) private var goal = ""
    @AppStorage(OnboardingAnswers.levelKey) private var level = ""
    @AppStorage(OnboardingAnswers.dailyMinutesKey) private var dailyMinutes = 5
    @State private var page = 0
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                switch page {
                case 0:
                    ChoicePage(title: "What brings you to Backprop?", options: OnboardingAnswers.goals, selection: $goal) { page = 1 }
                case 1:
                    ChoicePage(title: "How much ML do you know?", options: OnboardingAnswers.levels, selection: $level) { page = 2 }
                case 2:
                    ChoicePage(
                        title: "How much time per day?",
                        options: OnboardingAnswers.dailyMinutes.map { "\($0) minutes" },
                        selection: Binding(
                            get: { "\(dailyMinutes) minutes" },
                            set: { dailyMinutes = Int($0.split(separator: " ").first ?? "") ?? 5 }
                        )
                    ) { page = 3 }
                default:
                    PlanPage(goal: goal, level: level, dailyMinutes: dailyMinutes) { showPaywall = true }
                }
            }
            .padding()
            .animation(.default, value: page)
            .toolbar {
                if page > 0 {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Back") { page -= 1 }
                    }
                }
            }
        }
        .sheet(isPresented: $showPaywall, onDismiss: onFinish) {
            PaywallSheet()
        }
    }
}

private struct ChoicePage: View {
    let title: String
    let options: [String]
    @Binding var selection: String
    let onNext: () -> Void

    var body: some View {
        Text(title).font(.largeTitle.bold())
        VStack(spacing: 12) {
            ForEach(options, id: \.self) { option in
                Button {
                    selection = option
                    onNext()
                } label: {
                    HStack {
                        Text(option)
                        Spacer()
                        if selection == option { Image(systemName: "checkmark") }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        Spacer()
    }
}

private struct PlanPage: View {
    let goal: String
    let level: String
    let dailyMinutes: Int
    let onContinue: () -> Void

    private var startTrack: String {
        level == OnboardingAnswers.levels[0] ? "Data foundations" : "Classic ML"
    }

    var body: some View {
        Text("Your plan").font(.largeTitle.bold())
        VStack(alignment: .leading, spacing: 12) {
            Label("Start with \(startTrack)", systemImage: "flag")
            Label("\(dailyMinutes) minutes a day", systemImage: "clock")
            Label("Interactive sims in every chapter", systemImage: "hand.draw")
            if !goal.isEmpty { Label("Goal: \(goal)", systemImage: "target") }
        }
        .font(.title3)
        Spacer()
        Button(action: onContinue) {
            Text("Continue").frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }
}
