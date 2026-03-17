import Foundation

@MainActor
final class SessionEngine: ObservableObject {

    enum State: Equatable {
        case showingIntro
        case showingTheoryCard(MiniTheoryData, subTopic: String)
        case answering
        case showingFeedback
        case completed
        case gameOver

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.showingIntro, .showingIntro),
                 (.answering, .answering),
                 (.showingFeedback, .showingFeedback),
                 (.completed, .completed),
                 (.gameOver, .gameOver):
                return true
            case (.showingTheoryCard(let d1, let s1), .showingTheoryCard(let d2, let s2)):
                return d1 == d2 && s1 == s2
            default:
                return false
            }
        }
    }

    // MARK: - Published

    @Published private(set) var currentIndex: Int = 0
    @Published private(set) var hearts: Int
    @Published private(set) var state: State = .answering
    @Published private(set) var lastAnswerWasCorrect: Bool = false
    /// Character comment shown during .showingFeedback. Nil when character has nothing to say.
    @Published private(set) var characterComment: String? = nil

    // MARK: - Private

    private let items: [SessionItem]
    private(set) var correctCount: Int = 0
    private var answeredCount: Int = 0
    private var theoryCardsShown: Int = 0
    /// Tracks sub-topics whose theory cards were dismissed this session (in-memory only).
    private var seenSubTopicsThisSession: Set<String> = []

    /// Per-question answer log: accumulated as the session progresses.
    private(set) var answeredQuestions: [(questionId: String, wasWrong: Bool, firstAttempt: Bool)] = []

    // MARK: - Character Comment Tracking

    /// Question IDs that were answered wrong in previous sessions.
    let previouslyWrongQuestionIds: Set<String>
    /// True after the first wrong answer comment has been shown once this session.
    private var firstWrongCommentShown: Bool = false
    /// Number of consecutive correct answers since last wrong or last 3-streak trigger.
    private var consecutiveCorrectCount: Int = 0

    let isBeltTest: Bool
    let coachIntro: String?
    let streak: Int

    private let defaults: UserDefaults

    // MARK: - Init (items-based)

    init(
        items: [SessionItem],
        isBeltTest: Bool = false,
        coachIntro: String? = nil,
        streak: Int = 0,
        defaults: UserDefaults = .standard,
        previouslyWrongQuestionIds: Set<String> = []
    ) {
        self.isBeltTest = isBeltTest
        self.coachIntro = coachIntro
        self.streak = streak
        self.defaults = defaults
        self.hearts = isBeltTest ? 3 : UserProfile.maxHearts
        self.previouslyWrongQuestionIds = previouslyWrongQuestionIds

        // Process items: shuffle options for non-trueFalse questions
        self.items = items.map { item in
            switch item {
            case .question(let q):
                guard q.format != .trueFalse, let opts = q.options else { return item }
                var mutable = q
                mutable.options = opts.shuffled()
                return .question(mutable)
            case .theoryCard:
                return item
            }
        }

        // Set initial state: scan processed items to find what to show first
        if items.isEmpty {
            self.state = .completed
        } else if coachIntro != nil {
            self.state = .showingIntro
        } else {
            self.state = Self.computeInitialState(
                processedItems: self.items,
                isBeltTest: isBeltTest,
                defaults: defaults
            )
        }
    }

    /// Pure static helper — computes initial state from processed items list.
    /// Called from designated init, so must be static (no access to self needed).
    private static func computeInitialState(
        processedItems: [SessionItem],
        isBeltTest: Bool,
        defaults: UserDefaults
    ) -> State {
        if processedItems.isEmpty { return .completed }
        for item in processedItems {
            switch item {
            case .question:
                return .answering
            case .theoryCard(let data, let subTopic):
                if !isBeltTest && !defaults.bool(forKey: "theory_seen_\(subTopic)") {
                    return .showingTheoryCard(data, subTopic: subTopic)
                }
                // Skip seen/belt-test theory cards — continue to next item
            }
        }
        return .completed
    }

    /// No-op — initial state is resolved inline in items-based init.
    private func resolveInitialState() {}

    // MARK: - Convenience Init (questions only — backward compatible)

    init(
        questions: [Question],
        isBeltTest: Bool = false,
        coachIntro: String? = nil,
        streak: Int = 0,
        previouslyWrongQuestionIds: Set<String> = []
    ) {
        let ordered = isBeltTest ? questions.shuffled() : questions
        let processedItems: [SessionItem] = ordered.map { q in
            guard q.format != .trueFalse, let opts = q.options else { return .question(q) }
            var mutable = q
            mutable.options = opts.shuffled()
            return .question(mutable)
        }

        self.isBeltTest = isBeltTest
        self.coachIntro = coachIntro
        self.streak = streak
        self.defaults = .standard
        self.hearts = isBeltTest ? 3 : UserProfile.maxHearts
        self.previouslyWrongQuestionIds = previouslyWrongQuestionIds
        self.items = processedItems

        if questions.isEmpty {
            self.state = .completed
        } else if coachIntro != nil {
            self.state = .showingIntro
        } else {
            self.state = .answering
        }
    }

    // MARK: - Computed

    var currentQuestion: Question? {
        guard currentIndex < items.count else { return nil }
        if case .question(let q) = items[currentIndex] { return q }
        return nil
    }

    /// Progress only counts questions, not theory cards.
    var progress: Double {
        let totalQuestions = items.filter { if case .question = $0 { return true }; return false }.count
        guard totalQuestions > 0 else { return 0 }
        return Double(answeredCount) / Double(totalQuestions)
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
        // After intro, find the first item
        state = Self.nextStateAfterAdvancing(
            items: items,
            fromIndex: -1,
            isBeltTest: isBeltTest,
            theoryCardsShown: theoryCardsShown,
            defaults: defaults,
            fallback: .answering
        )
        // Update currentIndex if needed
        if case .showingTheoryCard = state {
            // index stays at 0 (theory card at index 0)
        } else {
            // Move to first question
            currentIndex = firstQuestionIndex() ?? 0
        }
    }

    func dismissTheoryCard() {
        guard case .showingTheoryCard(_, let subTopic) = state else { return }
        theoryCardsShown += 1
        // Mark this subTopic as seen in-memory so it won't show again this session.
        // Persistent storage of "seen" state is handled externally (e.g. SessionView calls
        // UserDefaults.standard.set(true, forKey: "theory_seen_\(subTopic)") after dismiss).
        seenSubTopicsThisSession.insert(subTopic)

        // Advance to next item
        currentIndex += 1
        advanceToNextItem()
    }

    func submitAnswer(_ answer: String) {
        guard state == .answering, let question = currentQuestion else { return }
        answeredCount += 1
        lastAnswerWasCorrect = (answer == question.correctAnswer)
        answeredQuestions.append((
            questionId: question.id,
            wasWrong: !lastAnswerWasCorrect,
            firstAttempt: true
        ))
        if lastAnswerWasCorrect {
            correctCount += 1
            consecutiveCorrectCount += 1
            characterComment = computeCorrectComment(for: question)
        } else {
            hearts = max(0, hearts - 1)
            consecutiveCorrectCount = 0
            characterComment = computeWrongComment()
        }
        if hearts == 0 {
            state = .gameOver
        } else {
            state = .showingFeedback
        }
    }

    func advance() {
        guard state == .showingFeedback else { return }
        characterComment = nil
        currentIndex += 1
        advanceToNextItem()
    }

    // MARK: - Character Comment Helpers

    private func computeCorrectComment(for question: Question) -> String? {
        // Priority 1: previously-wrong question answered correctly
        if previouslyWrongQuestionIds.contains(question.id) {
            consecutiveCorrectCount = 0 // reset streak — context message counts as "special"
            return L10n.Session.characterCommentPreviouslyWrong
        }
        // Priority 2: exactly 3 consecutive correct answers
        if consecutiveCorrectCount == 3 {
            consecutiveCorrectCount = 0 // reset after showing
            return L10n.Session.characterCommentThreeInARow
        }
        return nil
    }

    private func computeWrongComment() -> String? {
        guard !firstWrongCommentShown else { return nil }
        firstWrongCommentShown = true
        return L10n.Session.characterCommentFirstWrong
    }

    // MARK: - Private Helpers

    private func advanceToNextItem() {
        if currentIndex >= items.count {
            state = .completed
            return
        }

        let item = items[currentIndex]
        switch item {
        case .question:
            state = .answering
        case .theoryCard(let data, let subTopic):
            // Skip if: belt test, already shown 2 cards, seen in persistent storage, or seen this session
            if isBeltTest
                || theoryCardsShown >= 2
                || defaults.bool(forKey: "theory_seen_\(subTopic)")
                || seenSubTopicsThisSession.contains(subTopic) {
                currentIndex += 1
                advanceToNextItem()
            } else {
                state = .showingTheoryCard(data, subTopic: subTopic)
            }
        }
    }

    private func firstQuestionIndex() -> Int? {
        items.indices.first { if case .question = items[$0] { return true }; return false }
    }

    /// Computes the initial state by scanning from the beginning.
    private static func nextStateAfterAdvancing(
        items: [SessionItem],
        fromIndex: Int,
        isBeltTest: Bool,
        theoryCardsShown: Int,
        defaults: UserDefaults,
        fallback: State
    ) -> State {
        let startIndex = fromIndex + 1
        guard startIndex < items.count else { return .completed }

        for i in startIndex..<items.count {
            let item = items[i]
            switch item {
            case .question:
                return fallback  // answering
            case .theoryCard(let data, let subTopic):
                if isBeltTest
                    || theoryCardsShown >= 2
                    || defaults.bool(forKey: "theory_seen_\(subTopic)") {
                    continue  // skip, look at next
                } else {
                    return .showingTheoryCard(data, subTopic: subTopic)
                }
            }
        }
        return .completed
    }
}
