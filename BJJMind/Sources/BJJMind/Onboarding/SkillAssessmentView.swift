import SwiftUI

struct SkillAssessmentView: View {
    let onComplete: (SkillLevel) -> Void

    private enum Phase {
        case blockAIntro
        case blockA(questionIndex: Int)   // 0=Q1, 1=Q2
        case blockBIntro
        case blockB(questionIndex: Int)   // 0-2 BJJ questions
        case result(SkillLevel)
    }

    @State private var phase: Phase = .blockAIntro
    @State private var duration: TrainingDuration = .lessThan6Months
    @State private var frequency: TrainingFrequency = .justStarted
    @State private var bjjCorrect: Int = 0
    @State private var bjjQuestions: [AssessmentQuestion] = []

    private var progressStep: Int {
        switch phase {
        case .blockAIntro:         return 0
        case .blockA(let i):       return i + 1
        case .blockBIntro:         return 2
        case .blockB(let i):       return i + 3
        case .result:              return 5
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if case .result = phase { } else {
                AppProgressBar(progress: Double(progressStep) / 5.0)
                    .accessibilityLabel(L10n.Assessment.progress(progressStep))
                    .padding(.horizontal, 24)
                    .padding(.top, 52)
            }

            switch phase {
            case .blockAIntro:
                AssessmentIntroBlock(
                    title: L10n.Assessment.blockATitle,
                    subtitle: L10n.Assessment.blockASubtitle,
                    onContinue: { phase = .blockA(questionIndex: 0) }
                )

            case .blockA(let idx):
                if idx == 0 {
                    ExperienceQuestionView(
                        prompt: L10n.Assessment.q1Prompt,
                        options: L10n.Assessment.q1Options,
                        onSelect: { selectedIdx in
                            duration = TrainingDuration(rawValue: selectedIdx) ?? .lessThan6Months
                            phase = .blockA(questionIndex: 1)
                        }
                    )
                } else {
                    ExperienceQuestionView(
                        prompt: L10n.Assessment.q2Prompt,
                        options: L10n.Assessment.q2Options,
                        onSelect: { selectedIdx in
                            frequency = TrainingFrequency(rawValue: selectedIdx) ?? .justStarted
                            phase = .blockBIntro
                        }
                    )
                }

            case .blockBIntro:
                AssessmentIntroBlock(
                    title: L10n.Assessment.blockBTitle,
                    subtitle: L10n.Assessment.blockBSubtitle,
                    onContinue: {
                        let diff = SkillAssessmentEngine.questionDifficulty(for: duration)
                        bjjQuestions = SkillAssessmentEngine.questions(forDifficulty: diff)
                        phase = .blockB(questionIndex: 0)
                    }
                )

            case .blockB(let idx):
                let q = bjjQuestions[idx]
                BJJQuestionView(question: q) { isCorrect in
                    if isCorrect { bjjCorrect += 1 }
                    if idx < 2 {
                        phase = .blockB(questionIndex: idx + 1)
                    } else {
                        let level = SkillAssessmentEngine.computeSkillLevel(
                            duration: duration, frequency: frequency, correctCount: bjjCorrect)
                        phase = .result(level)
                    }
                }

            case .result(let level):
                AssessmentResultView(level: level) { onComplete(level) }
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.25), value: progressStep)
    }
}

// MARK: - Sub-views

private struct AssessmentIntroBlock: View {
    let title: String
    let subtitle: String
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 12) {
                Text(title)
                    .font(.screenTitle)
                    .foregroundColor(.textPrimary)
                    .tracking(-0.5)
                    .multilineTextAlignment(.center)
                Text(subtitle)
                    .font(.bodyMd)
                    .foregroundColor(.textMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            Spacer()
            PrimaryButton(title: L10n.Assessment.blockIntroCta, action: onContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, 52)
        }
    }
}

private struct ExperienceQuestionView: View {
    let prompt: String
    let options: [String]
    let onSelect: (Int) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text(prompt)
                .font(.sectionTitle)
                .foregroundColor(.textPrimary)
                .tracking(-0.5)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 36)
                .padding(.bottom, 24)

            VStack(spacing: 10) {
                ForEach(options.indices, id: \.self) { idx in
                    Button(action: { onSelect(idx) }) {
                        HStack {
                            Text(options[idx])
                                .font(.labelXL)
                                .foregroundColor(.textPrimary)
                            Spacer()
                        }
                        .padding(.horizontal, 18)
                        .frame(height: 56)
                        .background(Color.cardBg)
                        .overlay(RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color(hex: "#f3f4f6"), lineWidth: 2.5))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            Spacer()
        }
    }
}

private struct BJJQuestionView: View {
    let question: AssessmentQuestion
    let onAnswer: (Bool) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text(question.prompt)
                .font(.sectionTitle)
                .foregroundColor(.textPrimary)
                .tracking(-0.5)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 36)
                .padding(.bottom, 24)

            VStack(spacing: 10) {
                ForEach(question.options, id: \.self) { option in
                    Button(action: { onAnswer(option == question.correctAnswer) }) {
                        HStack {
                            Text(option)
                                .font(.labelXL)
                                .foregroundColor(.textPrimary)
                            Spacer()
                        }
                        .padding(.horizontal, 18)
                        .frame(height: 56)
                        .background(Color.cardBg)
                        .overlay(RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color(hex: "#f3f4f6"), lineWidth: 2.5))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            Spacer()
        }
    }
}

private struct AssessmentResultView: View {
    let level: SkillLevel
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Text("🥋")
                .font(.system(size: 72))
                .padding(.bottom, 24)
            Text(L10n.Assessment.result(for: level))
                .font(.screenTitle)
                .foregroundColor(.textPrimary)
                .tracking(-0.5)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            PrimaryButton(title: L10n.Assessment.resultCta, action: onContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, 52)
        }
    }
}
