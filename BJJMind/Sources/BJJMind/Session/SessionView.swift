import SwiftUI
import AudioToolbox

struct SessionView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let unit: Unit
    let isBeltTest: Bool
    let streak: Int

    private let passThreshold = 0.7

    /// Loaded adaptively in `.task`; `nil` while fetch is in flight.
    @State private var loadedQuestions: [Question]? = nil

    init(unit: Unit, isBeltTest: Bool = false, streak: Int = 0) {
        self.unit = unit
        self.isBeltTest = isBeltTest
        self.streak = streak
    }

    var body: some View {
        ZStack {
            Color.screenBg.ignoresSafeArea()

            if let questions = loadedQuestions {
                // Questions are ready — hand off to the inner engine-driven view
                SessionEngineView(
                    questions: questions,
                    unit: unit,
                    isBeltTest: isBeltTest,
                    streak: streak
                )
            } else {
                // Fetching adaptive questions — show a brief loading indicator
                ProgressView()
                    .tint(.brand)
            }
        }
        .task {
            let questions = await appState.fetchQuestionsForSession(for: unit)
            loadedQuestions = questions
        }
    }
}

// MARK: - Engine-driven session (questions already resolved)

private struct SessionEngineView: View {
    @StateObject private var engine: SessionEngine
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let unit: Unit
    let isBeltTest: Bool

    private let passThreshold = 0.7

    init(questions: [Question], unit: Unit, isBeltTest: Bool, streak: Int) {
        self.unit = unit
        self.isBeltTest = isBeltTest
        _engine = StateObject(wrappedValue: SessionEngine(
            questions: questions,
            isBeltTest: isBeltTest,
            coachIntro: isBeltTest ? nil : unit.coachIntro,
            streak: streak
        ))
    }

    var body: some View {
        ZStack {
            Color.screenBg.ignoresSafeArea()

            switch engine.state {
            case .showingIntro:
                CoachIntroCard(text: engine.coachIntro ?? "", onTap: { engine.dismissIntro() })

            case .answering:
                QuestionView(engine: engine, unit: unit, isBeltTest: isBeltTest, onClose: { dismiss() })

            case .showingFeedback:
                ZStack(alignment: .bottom) {
                    QuestionView(engine: engine, unit: unit, isBeltTest: isBeltTest, onClose: {})
                        .opacity(0.3)
                        .allowsHitTesting(false)

                    FeedbackView(
                        isCorrect: engine.lastAnswerWasCorrect,
                        explanation: isBeltTest ? "" : (engine.currentQuestion?.explanation ?? ""),
                        coachNote: engine.lastAnswerWasCorrect ? nil : engine.currentQuestion?.coachNote,
                        onContinue: { engine.advance() }
                    )
                }

            case .completed:
                if isBeltTest {
                    beltTestResultView
                } else {
                    SummaryView(
                        xpEarned: engine.xpEarned,
                        accuracy: engine.accuracy,
                        heartsRemaining: engine.hearts,
                        onDone: {
                            appState.recordQuestionAnswers(engine.answeredQuestions)
                            appState.applySessionResult(SessionResult(
                                userId: appState.user.id,
                                unitId: unit.id,
                                completedAt: Date(),
                                xpEarned: engine.xpEarned,
                                accuracy: engine.accuracy,
                                heartsUsed: UserProfile.maxHearts - engine.hearts,
                                weakTags: []
                            ))
                            appState.completeUnit(id: unit.id)
                            dismiss()
                        }
                    )
                }

            case .gameOver:
                if isBeltTest {
                    BeltTestFailView(accuracy: engine.accuracy, reason: .outOfHearts, onDone: {
                        appState.recordBeltTestFail()
                        dismiss()
                    })
                } else {
                    GameOverView(onDone: { dismiss() })
                }
            }
        }
    }

    @ViewBuilder
    private var beltTestResultView: some View {
        let passed = engine.accuracy >= passThreshold
        if passed {
            BeltTestPassView(accuracy: engine.accuracy, onDone: {
                appState.passBeltTest()
                appState.applySessionResult(SessionResult(
                    userId: appState.user.id,
                    unitId: unit.id,
                    completedAt: Date(),
                    xpEarned: engine.xpEarned,
                    accuracy: engine.accuracy,
                    heartsUsed: 0,
                    weakTags: []
                ))
                dismiss()
            })
        } else {
            BeltTestFailView(accuracy: engine.accuracy, reason: .lowAccuracy, onDone: {
                appState.recordBeltTestFail()
                dismiss()
            })
        }
    }
}

// MARK: - Question View

private struct QuestionView: View {
    @ObservedObject var engine: SessionEngine
    let unit: Unit
    let isBeltTest: Bool
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack(spacing: 14) {
                CloseButton(action: onClose)
                AppProgressBar(
                    progress: engine.progress,
                    trackColor: isBeltTest ? Color(hex: "#fde68a") : Color(hex: "#ede9fe"),
                    fillColor: isBeltTest ? Color(hex: "#f59e0b") : Color.brand
                )
                HeartBar(current: engine.hearts)
            }
            .padding(.horizontal, 24)
            .padding(.top, 52)

            // Meta row
            HStack {
                if isBeltTest {
                    Text(L10n.Session.beltTestChip)
                        .font(.nunito(13, weight: .black))
                        .foregroundColor(Color(hex: "#92400e"))
                        .tracking(1)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(Color(hex: "#fef3c7"))
                        .overlay(Capsule().strokeBorder(Color(hex: "#fde68a"), lineWidth: 1.5))
                        .clipShape(Capsule())
                } else if let tag = engine.currentQuestion?.tags.first {
                    Text(tag.uppercased())
                        .font(.nunito(13, weight: .black))
                        .foregroundColor(.brand)
                        .tracking(1)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(Color.brandVeryPale)
                        .clipShape(Capsule())
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // Scene placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color(hex: "#f8f6ff"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .strokeBorder(Color.brandPale, lineWidth: 1.5)
                    )
                VStack(spacing: 8) {
                    Text("🤼")
                        .font(.system(size: 60))
                    Text(L10n.Session.position.uppercased())
                        .font(.nunito(10, weight: .black))
                        .foregroundColor(Color(hex: "#c4b5fd"))
                        .tracking(1)
                }
            }
            .frame(height: 180)
            .padding(.horizontal, 20)

            // Question text
            VStack(alignment: .leading, spacing: 6) {
                Text(engine.currentQuestion?.prompt ?? "")
                    .font(.questionLg)
                    .foregroundColor(.textPrimary)
                    .tracking(-0.3)
                    .lineSpacing(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.vertical, 20)

            // Options — format-specific rendering
            optionsView(for: engine.currentQuestion)
                .padding(.horizontal, 20)

            Spacer()
        }
    }

    @ViewBuilder
    private func optionsView(for question: Question?) -> some View {
        if let question {
            let options = question.options ?? []
            switch question.format {
            case .trueFalse:
                TrueFalseOptionsView(onSubmit: { engine.submitAnswer($0) })
            case .fillBlank:
                FillBlankChipsView(options: options, onSubmit: { engine.submitAnswer($0) })
            case .mcq4:
                MCQ4GridView(options: options, onSubmit: { engine.submitAnswer($0) })
            default:
                VStack(spacing: 10) {
                    ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                        OptionButton(
                            letter: String(UnicodeScalar(65 + index)!),
                            text: option,
                            state: .normal
                        ) {
                            engine.submitAnswer(option)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - True/False Options

private struct TrueFalseOptionsView: View {
    let onSubmit: (String) -> Void

    var body: some View {
        HStack(spacing: 14) {
            TrueFalseButton(label: "TRUE", emoji: "✓", isTrue: true, onTap: { onSubmit("True") })
            TrueFalseButton(label: "FALSE", emoji: "✕", isTrue: false, onTap: { onSubmit("False") })
        }
    }
}

private struct TrueFalseButton: View {
    let label: String
    let emoji: String
    let isTrue: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(isTrue ? Color(hex: "#16a34a") : Color(hex: "#dc2626"))
                Text(label)
                    .font(.nunito(16, weight: .black))
                    .foregroundColor(isTrue ? Color(hex: "#16a34a") : Color(hex: "#dc2626"))
                    .tracking(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(isTrue ? Color(hex: "#f0fdf4") : Color(hex: "#fef2f2"))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(
                        isTrue ? Color(hex: "#86efac") : Color(hex: "#fca5a5"),
                        lineWidth: 2.5
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Fill Blank Chips

private struct FillBlankChipsView: View {
    let options: [String]
    let onSubmit: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Session.fillBlankHint)
                .font(.nunito(11, weight: .bold))
                .foregroundColor(Color(hex: "#a78bfa"))
                .tracking(0.5)

            FlowLayout(spacing: 10) {
                ForEach(options, id: \.self) { option in
                    Button(action: { onSubmit(option) }) {
                        Text(option)
                            .font(.nunito(15, weight: .bold))
                            .foregroundColor(.brand)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(Color.brandVeryPale)
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.brandPale, lineWidth: 2)
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - MCQ4 Grid

private struct MCQ4GridView: View {
    let options: [String]
    let onSubmit: (String) -> Void

    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                MCQ4OptionButton(
                    letter: String(UnicodeScalar(65 + index)!),
                    text: option,
                    state: .normal
                ) {
                    onSubmit(option)
                }
            }
        }
    }
}

private struct MCQ4OptionButton: View {
    let letter: String
    let text: String
    let state: OptionState
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        VStack(spacing: 10) {
            Text(letter)
                .font(.nunito(15, weight: .black))
                .foregroundColor(letterColor)
                .frame(width: 32, height: 32)
                .background(letterBg)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(text)
                .font(.nunito(14, weight: .bold))
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 10)
        .padding(.vertical, 14)
        .background(isPressed ? Color.brandVeryPale : cardBg)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(isPressed ? Color.brand : borderColor, lineWidth: 2.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.easeOut(duration: 0.1), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in
                    isPressed = false
                    playAnswerFeedback()
                    onTap()
                }
        )
    }

    private var letterBg: Color {
        switch state {
        case .normal:  return Color.brandVeryPale
        case .correct: return Color.successPale
        case .wrong:   return Color.errorPale
        }
    }
    private var letterColor: Color {
        switch state {
        case .normal:  return .brand
        case .correct: return Color(hex: "#16a34a")
        case .wrong:   return .error
        }
    }
    private var textColor: Color {
        switch state {
        case .normal:  return .textPrimary
        case .correct: return Color(hex: "#15803d")
        case .wrong:   return Color(hex: "#dc2626")
        }
    }
    private var borderColor: Color {
        switch state {
        case .normal:  return Color.brandPale
        case .correct: return Color.successLight
        case .wrong:   return Color.errorLight
        }
    }
    private var cardBg: Color {
        switch state {
        case .normal:  return .white
        case .correct: return Color(hex: "#f0fdf4")
        case .wrong:   return Color(hex: "#fef2f2")
        }
    }
}

// MARK: - Flow Layout (word-wrap)

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? UIScreen.main.bounds.width
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
            if x + size.width > maxWidth && x > 0 {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        y += rowHeight
        return CGSize(width: maxWidth, height: y)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(ProposedViewSize(width: bounds.width, height: nil))
            if x + size.width > bounds.maxX && x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Haptic + Sound

private func playAnswerFeedback() {
    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    AudioServicesPlaySystemSound(1104)
}

// MARK: - Option Button

enum OptionState { case normal, correct, wrong }

struct OptionButton: View {
    let letter: String
    let text: String
    let state: OptionState
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        HStack(spacing: 14) {
            Text(letter)
                .font(.optionLetter)
                .foregroundColor(letterColor)
                .frame(width: 36, height: 36)
                .background(letterBg)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(text)
                .font(.optionText)
                .foregroundColor(textColor)
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 62)
        .background(isPressed ? Color.brandVeryPale : cardBg)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(isPressed ? Color.brand : borderColor, lineWidth: 2.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.easeOut(duration: 0.1), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in
                    isPressed = false
                    playAnswerFeedback()
                    onTap()
                }
        )
    }

    private var letterBg: Color {
        switch state {
        case .normal:  return Color.brandVeryPale
        case .correct: return Color.successPale
        case .wrong:   return Color.errorPale
        }
    }
    private var letterColor: Color {
        switch state {
        case .normal:  return .brand
        case .correct: return Color(hex: "#16a34a")
        case .wrong:   return .error
        }
    }
    private var textColor: Color {
        switch state {
        case .normal:  return .textPrimary
        case .correct: return Color(hex: "#15803d")
        case .wrong:   return Color(hex: "#dc2626")
        }
    }
    private var borderColor: Color {
        switch state {
        case .normal:  return Color.brandPale
        case .correct: return Color.successLight
        case .wrong:   return Color.errorLight
        }
    }
    private var cardBg: Color {
        switch state {
        case .normal:  return .white
        case .correct: return Color(hex: "#f0fdf4")
        case .wrong:   return Color(hex: "#fef2f2")
        }
    }
}

// MARK: - Coach Intro Card

private struct CoachIntroCard: View {
    let text: String
    let onTap: () -> Void

    var body: some View {
        ZStack {
            Color.screenBg.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Image("marco")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)

                VStack(spacing: 12) {
                    Text(L10n.Coach.name.uppercased())
                        .font(.nunito(12, weight: .black))
                        .foregroundColor(.brand)
                        .tracking(1.5)

                    Text(text)
                        .font(.bodyLg)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)
                }

                Spacer()

                Button(action: onTap) {
                    Text(L10n.Coach.tapToStart)
                        .font(.buttonLg)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(Color.brand)
                        .clipShape(Capsule())
                        .shadow(color: Color(hex: "#5b21b6"), radius: 0, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 52)
            }
        }
    }
}

// MARK: - Game Over

private struct GameOverView: View {
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("💔")
                .font(.system(size: 72))
            Text(L10n.GameOver.title)
                .font(.screenTitle)
                .foregroundColor(.textPrimary)
            Text(L10n.GameOver.message)
                .font(.bodyMd)
                .foregroundColor(.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
            PrimaryButton(title: L10n.GameOver.exit, action: onDone)
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
        }
    }
}
