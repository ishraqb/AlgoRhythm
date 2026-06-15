import Foundation

/// The result of a single swipe.
enum SwipeOutcome: String, Codable {
    case mastered   // swipe right
    case review     // swipe left
}

/// Rolling performance for one topic. `streak` is signed: positive after
/// consecutive masters, negative after consecutive reviews. The engine reads
/// it to decide when to move the difficulty tier.
struct TopicPerformance: Codable, Equatable {
    var tier: Difficulty = .easy
    var streak: Int = 0
    var masteredCount: Int = 0
    var reviewedCount: Int = 0

    var totalSeen: Int { masteredCount + reviewedCount }

    var masteryRate: Double {
        guard totalSeen > 0 else { return 0 }
        return Double(masteredCount) / Double(totalSeen)
    }
}

/// All per-topic performance for the signed-in user. Mirrors what we sync to
/// DynamoDB keyed by the Cognito `sub`.
struct UserPerformance: Codable, Equatable {
    var topics: [Topic: TopicPerformance] = [:]

    func performance(for topic: Topic) -> TopicPerformance {
        topics[topic] ?? TopicPerformance()
    }

    mutating func record(_ outcome: SwipeOutcome, for topic: Topic, tier: Difficulty) {
        var perf = performance(for: topic)
        switch outcome {
        case .mastered:
            perf.masteredCount += 1
            perf.streak = max(perf.streak, 0) + 1
        case .review:
            perf.reviewedCount += 1
            perf.streak = min(perf.streak, 0) - 1
        }
        perf.tier = tier
        topics[topic] = perf
    }
}
