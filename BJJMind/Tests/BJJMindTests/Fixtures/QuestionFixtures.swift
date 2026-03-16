import Foundation
@testable import BJJMind

enum QuestionFixtures {

    /// Standard question with full field set
    static func make(
        id: String = "q-fixture",
        topic: String = "closed_guard",
        subTopic: String = "posture_defense",
        format: QuestionFormat = .mcq4,
        difficulty: Int = 1,
        language: String = "en"
    ) -> Question {
        Question(
            id: id,
            unitId: nil,
            format: format,
            prompt: "Fixture question \(id)",
            options: ["A", "B", "C", "D"],
            correctAnswer: "A",
            explanation: "A is correct",
            tags: [],
            difficulty: difficulty,
            sceneImageName: nil,
            topic: topic,
            subTopic: subTopic,
            language: language
        )
    }

    /// mcq3 format question (must never appear in sessions)
    static func makeMcq3(id: String = "mcq3-fixture", topic: String = "closed_guard") -> Question {
        Question(
            id: id, unitId: nil, format: .mcq3,
            prompt: "Battle question \(id)",
            options: ["A", "B", "C"],
            correctAnswer: "A",
            explanation: "",
            tags: [], difficulty: 1, sceneImageName: nil,
            topic: topic, subTopic: "posture_defense", language: "en"
        )
    }

    /// Batch of N questions, all unique IDs, same topic/subTopic
    static func batch(
        count: Int,
        topic: String = "closed_guard",
        subTopic: String = "posture_defense",
        format: QuestionFormat = .mcq4
    ) -> [Question] {
        (0..<count).map { i in
            make(id: "q-\(topic)-\(subTopic)-\(i)", topic: topic, subTopic: subTopic, format: format)
        }
    }
}
