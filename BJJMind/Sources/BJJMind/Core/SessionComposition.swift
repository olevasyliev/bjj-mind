import Foundation

// MARK: - SubTopicProgress

struct SubTopicProgress: Equatable {
    let slug: String
    let title: String
    let avgStrength: Int       // 0-100
    let questionsSeen: Int
    let totalQuestions: Int
    let isUnlocked: Bool
    let isMastered: Bool       // avgStrength >= 70
}

// MARK: - CycleProgress

struct CycleProgress: Equatable {
    let cycleNumber: Int
    let topic: String
    let subTopics: [SubTopicProgress]

    var isBossUnlocked: Bool {
        guard !subTopics.isEmpty else { return false }
        return subTopics.allSatisfy { $0.avgStrength >= 70 }
    }

    var isBossLocked: Bool {
        subTopics.contains { $0.avgStrength < 50 }
    }

    var avgStrength: Int {
        guard !subTopics.isEmpty else { return 0 }
        return subTopics.map(\.avgStrength).reduce(0, +) / subTopics.count
    }

    /// Returns updated SubTopicProgress array with sequential unlock gates applied.
    /// First sub-topic always unlocked. Sub-topic N+1 unlocks when sub-topic N avgStrength >= 60.
    func subTopicUnlockStates() -> [SubTopicProgress] {
        guard !subTopics.isEmpty else { return [] }
        var result: [SubTopicProgress] = []
        for (i, sub) in subTopics.enumerated() {
            let isUnlocked: Bool
            if i == 0 {
                isUnlocked = true
            } else {
                isUnlocked = result[i - 1].avgStrength >= 60
            }
            result.append(SubTopicProgress(
                slug: sub.slug,
                title: sub.title,
                avgStrength: sub.avgStrength,
                questionsSeen: sub.questionsSeen,
                totalQuestions: sub.totalQuestions,
                isUnlocked: isUnlocked,
                isMastered: sub.isMastered
            ))
        }
        return result
    }
}

// MARK: - SessionItem

enum SessionItem: Equatable {
    case question(Question)
    case theoryCard(MiniTheoryData, subTopic: String)

    static func == (lhs: SessionItem, rhs: SessionItem) -> Bool {
        switch (lhs, rhs) {
        case (.question(let q1), .question(let q2)):
            return q1.id == q2.id
        case (.theoryCard(let d1, let s1), .theoryCard(let d2, let s2)):
            return d1 == d2 && s1 == s2
        default:
            return false
        }
    }
}

// MARK: - SessionCompositionBuilder

enum SessionCompositionBuilder {

    /// Composes a session from three priority buckets: new (60%), weak (25%), refresh (15%).
    /// Filters out mcq3 questions. Deduplicates across buckets. Applies language filter.
    /// Returns ordered result: new-bucket first, weak-bucket second, refresh-bucket last.
    static func compose(
        newQuestions: [Question],
        weakQuestions: [Question],
        refreshQuestions: [Question],
        sessionSize: Int = 9,
        language: String = "en"
    ) -> [Question] {
        // Language filter + mcq3 exclusion
        let filterByLang: ([Question]) -> [Question] = { qs in
            qs.filter { $0.language == language && $0.format != .mcq3 }
        }

        let filteredNew     = filterByLang(newQuestions)
        let filteredWeak    = filterByLang(weakQuestions)
        let filteredRefresh = filterByLang(refreshQuestions)

        // Calculate target counts (60/25/15)
        let targetNew     = Int((Double(sessionSize) * 0.60).rounded())
        let targetWeak    = Int((Double(sessionSize) * 0.25).rounded())
        let targetRefresh = sessionSize - targetNew - targetWeak

        // Deduplicate: question can only appear in one bucket
        var usedIds = Set<String>()

        func take(_ pool: [Question], count: Int) -> [Question] {
            var result: [Question] = []
            for q in pool {
                if result.count >= count { break }
                if !usedIds.contains(q.id) {
                    usedIds.insert(q.id)
                    result.append(q)
                }
            }
            return result
        }

        let newSlice     = take(filteredNew,     count: targetNew)
        var weakSlice    = take(filteredWeak,    count: targetWeak)
        var refreshSlice = take(filteredRefresh, count: targetRefresh)

        // Backfill: if new bucket is short, take more from weak
        let newShortfall = targetNew - newSlice.count
        if newShortfall > 0 {
            let extra = take(filteredWeak, count: newShortfall)
            weakSlice += extra
        }

        // Backfill: if still short, take more from refresh
        var totalSoFar = newSlice.count + weakSlice.count + refreshSlice.count
        if totalSoFar < sessionSize {
            let remaining = sessionSize - totalSoFar
            let extraRefresh = take(filteredRefresh, count: remaining)
            refreshSlice += extraRefresh
        }

        // Final backfill: if still short, take more from new bucket
        totalSoFar = newSlice.count + weakSlice.count + refreshSlice.count
        var finalNewSlice = newSlice
        if totalSoFar < sessionSize {
            let remaining = sessionSize - totalSoFar
            let extraNew = take(filteredNew, count: remaining)
            finalNewSlice += extraNew
        }

        return finalNewSlice + weakSlice + refreshSlice
    }
}

// MARK: - StrengthTier

enum StrengthTier: Equatable {
    case weak       // 0-49
    case learning   // 50-69
    case solid      // 70-89
    case mastered   // 90-100

    init(strength: Int) {
        switch strength {
        case 0..<50:   self = .weak
        case 50..<70:  self = .learning
        case 70..<90:  self = .solid
        default:       self = .mastered
        }
    }

    var label: String {
        switch self {
        case .weak:     return "Weak"
        case .learning: return "Learning"
        case .solid:    return "Solid"
        case .mastered: return "Mastered"
        }
    }

    var isMastered: Bool { self == .mastered }
    var isSolid: Bool    { self == .solid || self == .mastered }
}

// MARK: - StrengthDecayCalculator

enum StrengthDecayCalculator {

    /// Applies time-based decay: -5 per 3-day period elapsed since lastSeen.
    /// Floor at 0. If lastSeen is nil, no decay applied.
    static func apply(to stat: QuestionStat, referenceDate: Date = Date()) -> Int {
        guard let lastSeen = stat.lastSeen, stat.strength > 0 else {
            return stat.strength
        }
        let elapsed = referenceDate.timeIntervalSince(lastSeen)
        let daysPassed = Int(elapsed / 86400)
        let periods = daysPassed / 3
        let decay = periods * 5
        return max(0, stat.strength - decay)
    }
}
