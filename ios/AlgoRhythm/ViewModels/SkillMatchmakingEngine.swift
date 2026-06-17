import Foundation

/// Decides which card to show next based on how the user is doing per topic.
///
/// The idea mirrors skill-based matchmaking: keep the player near the edge of
/// their ability. A run of correct answers nudges the topic's difficulty up; a
/// run of misses pulls it back down to shore up fundamentals. Cards are then
/// drawn at (or just below) the current tier for each topic.
struct SkillMatchmakingEngine {
    /// Consecutive masters before we promote a topic to a harder tier.
    var promoteAfter = 3
    /// Consecutive reviews before we drop a topic to an easier tier.
    var demoteAfter = 2

    /// Returns the tier a topic should move to after recording `outcome`.
    /// `streak` is the signed streak *after* the outcome was applied.
    func adjustedTier(current: Difficulty, streak: Int) -> Difficulty {
        if streak >= promoteAfter {
            return current.harder()
        }
        if streak <= -demoteAfter {
            return current.easier()
        }
        return current
    }

    /// Picks the next card from `pool` given the user's per-topic standing.
    ///
    /// Preference order:
    ///   1. weakest topic first (lowest mastery rate among topics that still
    ///      have unseen cards), so struggling areas resurface
    ///   2. within that topic, the card closest to the user's current tier
    ///
    /// `seenIDs` are cards already answered this session and are skipped until
    /// the pool is exhausted.
    func nextCard(
        from pool: [Card],
        performance: UserPerformance,
        seenIDs: Set<String>
    ) -> Card? {
        let unseen = pool.filter { !seenIDs.contains($0.id) }
        let candidates = unseen.isEmpty ? pool : unseen
        guard !candidates.isEmpty else { return nil }

        let topicsPresent = Set(candidates.map { $0.topic })
        let weakestTopic = topicsPresent.min { lhs, rhs in
            performance.performance(for: lhs).masteryRate <
                performance.performance(for: rhs).masteryRate
        }
        guard let topic = weakestTopic else { return candidates.first }

        let targetTier = performance.performance(for: topic).tier
        let topicCards = candidates.filter { $0.topic == topic }

        // Closest difficulty to where the user is sitting for this topic.
        return topicCards.min { lhs, rhs in
            abs(lhs.difficulty.rawValue - targetTier.rawValue) <
                abs(rhs.difficulty.rawValue - targetTier.rawValue)
        }
    }
}
