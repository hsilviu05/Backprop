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

    var body: some View {
        VStack(spacing: 0) {
            ProgressView(value: session.progress)
                .padding(.horizontal)
                .padding(.top, 8)

            ScrollView {
                Group {
                    if let step = session.currentStep {
                        StepView(step: step, stepIndex: session.stepIndex, session: session)
                    } else {
                        LessonSummaryView(correct: session.correctCount, total: session.questionCount)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(action: primaryAction) {
                Text(session.isFinished ? "Done" : "Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!session.isFinished && !session.canAdvance)
            .padding()
        }
        .navigationTitle(session.lesson.title)
        .navigationBarTitleDisplayMode(.inline)
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
            session.advance()
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

    var body: some View {
        switch step {
        case .text(let markdown):
            Text(LocalizedStringKey(markdown))
                .font(.body)
                .lineSpacing(4)
        case .widget(let kind, let caption):
            VStack(alignment: .leading, spacing: 12) {
                if !caption.isEmpty {
                    Text(LocalizedStringKey(caption)).font(.callout).foregroundStyle(.secondary)
                }
                InteractiveWidget(kind: kind)
            }
        case .quiz(let quiz):
            QuizView(quiz: quiz, selection: session.selection(at: stepIndex)) { session.select(choice: $0) }
        }
    }
}

struct QuizView: View {
    let quiz: QuizStep
    let selection: Int?
    let onSelect: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(quiz.question).font(.title3.weight(.semibold))
            ForEach(Array(quiz.choices.enumerated()), id: \.offset) { index, choice in
                Button { onSelect(index) } label: {
                    HStack {
                        Text(choice).multilineTextAlignment(.leading)
                        Spacer()
                        if let selection, index == quiz.answerIndex {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                .accessibilityLabel(selection == index ? "Correct" : "Correct answer")
                        } else if selection == index {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
                                .accessibilityLabel("Incorrect")
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .disabled(selection != nil)
            }
            if let selection {
                Text(selection == quiz.answerIndex ? "Correct!" : "Not quite.")
                    .font(.headline)
                Text(LocalizedStringKey(quiz.explanation)).foregroundStyle(.secondary)
            }
        }
    }
}

private struct LessonSummaryView: View {
    let correct: Int
    let total: Int

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("Lesson complete").font(.title2.bold())
            if total > 0 {
                Text("\(correct) of \(total) correct")
                    .foregroundStyle(.secondary)
            }
            Text("+\(XP.perLesson + correct * XP.perCorrectAnswer) XP").font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}
