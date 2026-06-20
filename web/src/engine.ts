import {
  Card,
  DifficultyName,
  DIFFICULTY_RANK,
  TopicId,
  UserPerformance,
  defaultPerformance,
  easier,
  harder,
  masteryRate,
} from "./types";

// Skill-based matchmaking: keep the learner near the edge of their ability.
// A run of masters nudges a topic's tier up; a run of reviews pulls it back
// down. Cards are drawn at (or just below) the current tier per topic.
const PROMOTE_AFTER = 3;
const DEMOTE_AFTER = 2;

export function adjustedTier(current: DifficultyName, streak: number): DifficultyName {
  if (streak >= PROMOTE_AFTER) return harder(current);
  if (streak <= -DEMOTE_AFTER) return easier(current);
  return current;
}

function perfFor(performance: UserPerformance, topic: TopicId) {
  return performance[topic] ?? defaultPerformance();
}

// Preference order: weakest topic first (lowest mastery rate among topics that
// still have unseen cards), then the card closest to the user's current tier.
export function nextCard(
  pool: Card[],
  performance: UserPerformance,
  seenIds: Set<string>,
): Card | null {
  const unseen = pool.filter((c) => !seenIds.has(c.id));
  const candidates = unseen.length > 0 ? unseen : pool;
  if (candidates.length === 0) return null;

  const topicsPresent = Array.from(new Set(candidates.map((c) => c.topic)));
  let weakestTopic: TopicId | undefined;
  for (const topic of topicsPresent) {
    if (
      weakestTopic === undefined ||
      masteryRate(perfFor(performance, topic)) <
        masteryRate(perfFor(performance, weakestTopic))
    ) {
      weakestTopic = topic;
    }
  }
  if (weakestTopic === undefined) return candidates[0];

  const targetTier = DIFFICULTY_RANK[perfFor(performance, weakestTopic).tier];
  const topicCards = candidates.filter((c) => c.topic === weakestTopic);

  return topicCards.reduce((best, c) => {
    const dC = Math.abs(DIFFICULTY_RANK[c.difficulty] - targetTier);
    const dBest = Math.abs(DIFFICULTY_RANK[best.difficulty] - targetTier);
    return dC < dBest ? c : best;
  }, topicCards[0]);
}
