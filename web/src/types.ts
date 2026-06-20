// Domain model for the web edition, mirrored from the iOS app so behaviour
// stays identical across platforms.

export type Category = "algorithms" | "systemDesign";

export type TopicId =
  | "arrays"
  | "hashMaps"
  | "twoPointers"
  | "slidingWindow"
  | "trees"
  | "graphs"
  | "recursion"
  | "dynamicProgramming"
  | "bitManipulation"
  | "scalability"
  | "loadBalancing"
  | "caching"
  | "sharding"
  | "capTheorem"
  | "microservices"
  | "rateLimiting"
  | "messageQueues";

export type DifficultyName = "intro" | "easy" | "medium" | "hard" | "expert";

export type SwipeOutcome = "mastered" | "review";

// Difficulty doubles as the rank the matchmaking engine moves up and down.
export const DIFFICULTY_RANK: Record<DifficultyName, number> = {
  intro: 0,
  easy: 1,
  medium: 2,
  hard: 3,
  expert: 4,
};

const RANK_ORDER: DifficultyName[] = ["intro", "easy", "medium", "hard", "expert"];

export function harder(d: DifficultyName): DifficultyName {
  return RANK_ORDER[Math.min(DIFFICULTY_RANK[d] + 1, 4)];
}

export function easier(d: DifficultyName): DifficultyName {
  return RANK_ORDER[Math.max(DIFFICULTY_RANK[d] - 1, 0)];
}

export interface Card {
  id: string;
  topic: TopicId;
  difficulty: DifficultyName;
  prompt: string;
  solution: string;
  code: string;
  language: string;
  timeComplexity: string;
  spaceComplexity: string;
  source: string;
  license: string;
}

export interface TopicPerformance {
  tier: DifficultyName;
  streak: number;
  masteredCount: number;
  reviewedCount: number;
}

export type UserPerformance = Partial<Record<TopicId, TopicPerformance>>;

export const ALGORITHM_TOPICS: TopicId[] = [
  "arrays",
  "hashMaps",
  "twoPointers",
  "slidingWindow",
  "trees",
  "graphs",
  "recursion",
  "dynamicProgramming",
  "bitManipulation",
];

export const TOPIC_TITLES: Record<TopicId, string> = {
  arrays: "Arrays",
  hashMaps: "Hash Maps",
  twoPointers: "Two Pointers",
  slidingWindow: "Sliding Window",
  trees: "Trees",
  graphs: "Graphs",
  recursion: "Recursion",
  dynamicProgramming: "Dynamic Programming",
  bitManipulation: "Bit Manipulation",
  scalability: "Scalability",
  loadBalancing: "Load Balancing",
  caching: "Caching",
  sharding: "Sharding",
  capTheorem: "CAP Theorem",
  microservices: "Microservices",
  rateLimiting: "Rate Limiting",
  messageQueues: "Message Queues",
};

export const DIFFICULTY_TITLES: Record<DifficultyName, string> = {
  intro: "Intro",
  easy: "Easy",
  medium: "Medium",
  hard: "Hard",
  expert: "Expert",
};

export function categoryOf(topic: TopicId): Category {
  return ALGORITHM_TOPICS.includes(topic) ? "algorithms" : "systemDesign";
}

export function defaultPerformance(): TopicPerformance {
  return { tier: "easy", streak: 0, masteredCount: 0, reviewedCount: 0 };
}

export function masteryRate(p: TopicPerformance): number {
  const total = p.masteredCount + p.reviewedCount;
  return total > 0 ? p.masteredCount / total : 0;
}

export function hasCode(card: Card): boolean {
  return card.code.trim().length > 0;
}
