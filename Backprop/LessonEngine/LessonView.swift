import SwiftData
import SwiftUI

struct LessonView: View {
    let track: Track
    @State private var session: LessonSession
    @State private var saveError: String?
    @State private var didRecord = false
    @State private var showSoftPaywall = false

    @Environment(ContentLibrary.self) private var content
    @Environment(EntitlementStore.self) private var entitlements
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    init(lesson: Lesson, track: Track) {
        self.track = track
        _session = State(initialValue: LessonSession(lesson: lesson))
    }

    private var tint: Color { Theme.trackTint(track.id) }

    var body: some View {
        ScrollView {
            Group {
                if let step = session.currentStep {
                    StepView(step: step, stepIndex: session.stepIndex, session: session, tint: tint)
                } else {
                    LessonSummaryView(correct: session.correctCount, total: session.questionCount, tint: tint)
                }
            }
            .id(session.stepIndex)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .padding(Theme.padding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollBounceBehavior(.basedOnSize)
        .screenBackground(tint: tint)
        .safeAreaInset(edge: .top, spacing: 0) {
            LessonProgressBar(progress: session.progress, tint: tint)
                .padding(.horizontal, Theme.padding)
                .padding(.vertical, 8)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button(action: primaryAction) {
                Text(session.isFinished ? "Done" : "Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .primaryButtonStyle()
            .tint(tint)
            .disabled(!session.isFinished && !session.canAdvance)
            .padding(.horizontal, Theme.padding)
            .padding(.vertical, 10)
        }
        .navigationTitle(session.lesson.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onChange(of: session.isFinished) { _, finished in
            if finished { record() }
        }
        .alert("Couldn't save progress", isPresented: Binding(
            get: { saveError != nil }, set: { if !$0 { saveError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveError ?? "")
        }
        .sheet(isPresented: $showSoftPaywall, onDismiss: { dismiss() }) {
            PaywallSheet()
        }
    }

    private func primaryAction() {
        if session.isFinished {
            if !entitlements.isPro, content.isEndOfFreeContent(lessonID: session.lesson.id, in: track) {
                showSoftPaywall = true
            } else {
                dismiss()
            }
        } else {
            withAnimation(Theme.spring) { session.advance() }
        }
    }

    private func record() {
        guard !didRecord else { return }
        didRecord = true
        do {
            try ProgressRecorder.recordCompletion(
                lessonID: session.lesson.id,
                correct: session.correctCount,
                questionCount: session.questionCount,
                in: modelContext
            )
        } catch {
            saveError = error.localizedDescription
        }
    }
}

private struct StepView: View {
    let step: LessonStep
    let stepIndex: Int
    let session: LessonSession
    let tint: Color

    var body: some View {
        switch step {
        case .text(let markdown):
            Text(LocalizedStringKey(markdown))
                .font(.title3)
                .lineSpacing(6)
                .padding(.top, 12)
        case .widget(let kind, let caption):
            VStack(alignment: .leading, spacing: 14) {
                Label("Try it", systemImage: "hand.draw")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(tint)
                if !caption.isEmpty {
                    Text(LocalizedStringKey(caption)).font(.callout).foregroundStyle(.secondary)
                }
                InteractiveWidget(kind: kind)
            }
        case .quiz(let quiz):
            QuizView(quiz: quiz, selection: session.selection(at: stepIndex), tint: tint) { choice in
                withAnimation(Theme.spring) { session.select(choice: choice) }
            }
        }
    }
}

private struct LessonProgressBar: View {
    let progress: Double
    let tint: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(tint.opacity(0.15))
                Capsule().fill(tint)
                    .frame(width: max(8, geo.size.width * min(progress, 1)))
                    .animation(Theme.spring, value: progress)
            }
        }
        .frame(height: 6)
        .accessibilityElement()
        .accessibilityLabel("Lesson progress")
        .accessibilityValue("\(Int((progress * 100).rounded())) percent")
    }
}

struct QuizView: View {
    let quiz: QuizStep
    let selection: Int?
    var tint: Color = .accentColor
    let onSelect: (Int) -> Void

    private static let letters = ["A", "B", "C", "D", "E", "F"]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Quick check", systemImage: "questionmark.circle")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
            Text(quiz.question)
                .font(.title3.weight(.semibold))
                .padding(.bottom, 4)
            ForEach(Array(quiz.choices.enumerated()), id: \.offset) { index, choice in
                Button { onSelect(index) } label: {
                    ChoiceRow(
                        letter: index < Self.letters.count ? Self.letters[index] : "\(index + 1)",
                        text: choice,
                        state: state(for: index),
                        tint: tint
                    )
                }
                .buttonStyle(.plain)
                .allowsHitTesting(selection == nil)
            }
            if let selection {
                let correct = selection == quiz.answerIndex
                VStack(alignment: .leading, spacing: 6) {
                    Label(correct ? "Correct" : "Not quite", systemImage: correct ? "checkmark.circle.fill" : "lightbulb.fill")
                        .font(.headline)
                        .foregroundStyle(correct ? .green : .orange)
                    Text(LocalizedStringKey(quiz.explanation))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .padding(Theme.padding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardSurface(cornerRadius: Theme.smallCornerRadius, tint: correct ? .green : .orange)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sensoryFeedback(trigger: selection) { _, new in
            guard let new else { return nil }
            return new == quiz.answerIndex ? .success : .error
        }
    }

    private func state(for index: Int) -> ChoiceRow.RowState {
        guard let selection else { return .idle }
        if index == quiz.answerIndex { return .correct }
        if index == selection { return .wrong }
        return .dimmed
    }
}

private struct ChoiceRow: View {
    enum RowState { case idle, correct, wrong, dimmed }

    let letter: String
    let text: String
    let state: RowState
    let tint: Color

    private var accent: Color {
        switch state {
        case .correct: .green
        case .wrong: .red
        case .idle, .dimmed: tint
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(letter)
                .font(.subheadline.weight(.bold))
                .frame(width: 30, height: 30)
                .foregroundStyle(state == .correct || state == .wrong ? .white : accent)
                .background(
                    Circle().fill(state == .correct || state == .wrong ? accent : accent.opacity(0.15))
                )
            Text(text)
                .multilineTextAlignment(.leading)
                .foregroundStyle(.primary)
            Spacer(minLength: 4)
            if state == .correct {
                Image(systemName: "checkmark").foregroundStyle(.green).fontWeight(.bold)
                    .transition(.scale.combined(with: .opacity))
            } else if state == .wrong {
                Image(systemName: "xmark").foregroundStyle(.red).fontWeight(.bold)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .cardSurface(cornerRadius: Theme.smallCornerRadius, tint: state == .correct ? .green : state == .wrong ? .red : nil)
        .opacity(state == .dimmed ? 0.7 : 1)
        .scaleEffect(state == .wrong ? 0.98 : 1)
        .accessibilityElement(children: .combine)
        .accessibilityValue(state == .correct ? "Correct answer" : state == .wrong ? "Your answer, incorrect" : "")
    }
}

private struct LessonSummaryView: View {
    let correct: Int
    let total: Int
    let tint: Color
    @State private var celebrate = false

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 72))
                .foregroundStyle(tint)
                .symbolEffect(.bounce, value: celebrate)
            Text("Lesson complete").font(.title.bold())
            if total > 0 {
                Text("\(correct) of \(total) correct")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            Label("+\(XP.perLesson + correct * XP.perCorrectAnswer) XP", systemImage: "star.fill")
                .font(.headline)
                .foregroundStyle(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .cardSurface(cornerRadius: 999, tint: .yellow)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
        .onAppear { celebrate = true }
        .sensoryFeedback(.success, trigger: celebrate)
    }
}
