import Foundation

@MainActor
final class SessionEngine: ObservableObject {

    enum State: Equatable { case showingIntro, answering, showingFeedback, completed, gameOver }

    // MARK: - Published

    @Published private(set) var currentIndex: Int = 0
    @Published private(set) var hearts: Int
    @Published private(set) var state: State = .answering
    @Published private(set) var lastAnswerWasCorrect: Bool = false

    // MARK: - Private

    private let questions: [Question]
    private(set) var correctCount: Int = 0
    private var answeredCount: Int = 0

    /// Per-question answer log: accumulated as the session progresses.
    /// Each entry holds the question's stable id and whether it was answered wrong.
    private(set) var answeredQuestions: [(questionId: String, wasWrong: Bool)] = []

    let isBeltTest: Bool
    let coachIntro: String?
    let streak: Int

    // MARK: - Init

    init(questions: [Question], isBeltTest: Bool = false, coachIntro: String? = nil, streak: Int = 0) {
        let ordered = isBeltTest ? questions.shuffled() : questions
        // Shuffle options so the correct answer isn't always option A
        self.questions = ordered.map { q in
            guard q.format != .trueFalse, let opts = q.options else { return q }
            var mutable = q
            mutable.options = opts.shuffled()
            return mutable
        }
        self.isBeltTest = isBeltTest
        self.coachIntro = coachIntro
        self.streak = streak
        self.hearts = isBeltTest ? 3 : UserProfile.maxHearts
        self.state = questions.isEmpty ? .completed : (coachIntro != nil ? .showingIntro : .answering)
    }

    // MARK: - Computed

    var currentQuestion: Question? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(answeredCount) / Double(questions.count)
    }

    var accuracy: Double {
        guard answeredCount > 0 else { return 0 }
        return Double(correctCount) / Double(answeredCount)
    }

    var xpEarned: Int {
        let base = correctCount * 10 + hearts * 2
        let multiplier: Double
        switch streak {
        case 0:      multiplier = 1.0
        case 1...2:  multiplier = 1.1
        case 3...6:  multiplier = 1.25
        default:     multiplier = 1.5
        }
        return Int(Double(base) * multiplier)
    }

    // MARK: - Actions

    func dismissIntro() {
        guard state == .showingIntro else { return }
        state = .answering
    }

    func submitAnswer(_ answer: String) {
        guard state == .answering, let question = currentQuestion else { return }
        answeredCount += 1
        lastAnswerWasCorrect = (answer == question.correctAnswer)
        answeredQuestions.append((questionId: question.id, wasWrong: !lastAnswerWasCorrect))
        if lastAnswerWasCorrect {
            correctCount += 1
        } else {
            hearts = max(0, hearts - 1)
        }
        if hearts == 0 {
            state = .gameOver
        } else {
            state = .showingFeedback
        }
    }

    func advance() {
        guard state == .showingFeedback else { return }
        currentIndex += 1
        if currentIndex >= questions.count {
            state = .completed
        } else {
            state = .answering
        }
    }
}
