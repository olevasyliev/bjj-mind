import SwiftUI

struct SessionView: View {
    @StateObject private var engine: SessionEngine
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let unit: Unit
    let isBeltTest: Bool

    private let passThreshold = 0.7

    init(unit: Unit, isBeltTest: Bool = false) {
        self.unit = unit
        self.isBeltTest = isBeltTest
        _engine = StateObject(wrappedValue: SessionEngine(questions: unit.questions, isBeltTest: isBeltTest))
    }

    var body: some View {
        ZStack {
            Color.screenBg.ignoresSafeArea()

            switch engine.state {
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

            // Options
            VStack(spacing: 10) {
                ForEach(Array((engine.currentQuestion?.options ?? []).enumerated()), id: \.offset) { index, option in
                    OptionButton(
                        letter: String(UnicodeScalar(65 + index)!),
                        text: option,
                        state: .normal
                    ) {
                        engine.submitAnswer(option)
                    }
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
    }
}

// MARK: - Option Button

enum OptionState { case normal, correct, wrong }

struct OptionButton: View {
    let letter: String
    let text: String
    let state: OptionState
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Letter badge
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
            .background(cardBg)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(borderColor, lineWidth: 2.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
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
