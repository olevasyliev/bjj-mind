import Foundation

@MainActor
final class SessionEngine: ObservableObject {

    enum State: Equatable { case answering, showingFeedback, completed, gameOver }

    // MARK: - Published

    @Published private(set) var currentIndex: Int = 0
    @Published private(set) var hearts: Int
    @Published private(set) var state: State = .answering
    @Published private(set) var lastAnswerWasCorrect: Bool = false

    // MARK: - Private

    private let questions: [Question]
    private var correctCount: Int = 0
    private var answeredCount: Int = 0

    let isBeltTest: Bool

    // MARK: - Init

    init(questions: [Question], isBeltTest: Bool = false) {
        let ordered = isBeltTest ? questions.shuffled() : questions
        // Shuffle options so the correct answer isn't always option A
        self.questions = ordered.map { q in
            guard q.format != .trueFalse, let opts = q.options else { return q }
            var mutable = q
            mutable.options = opts.shuffled()
            return mutable
        }
        self.isBeltTest = isBeltTest
        self.hearts = isBeltTest ? 3 : UserProfile.maxHearts
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
        let base = correctCount * 10
        let heartBonus = hearts * 2
        return base + heartBonus
    }

    // MARK: - Actions

    func submitAnswer(_ answer: String) {
        guard state == .answering, let question = currentQuestion else { return }
        answeredCount += 1
        lastAnswerWasCorrect = (answer == question.correctAnswer)
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
