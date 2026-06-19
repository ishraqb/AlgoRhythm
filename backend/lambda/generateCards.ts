import { assertValidTopic, safeInt } from "./shared";

interface AppSyncEvent {
  arguments: { topic: string; count: number };
}

// Dynamic card generation using only free, local logic: we template prompts and
// vary their parameters. No external/paid model is involved, so generation
// costs nothing and stays fully original.
const TEMPLATES: Record<string, (seed: number) => { prompt: string; solution: string }> = {
  arrays: (n) => ({
    prompt: `Given an array of ${n} integers, return the running prefix sums.`,
    solution: "Carry a running total left to right, writing it at each index.",
  }),
  hashMaps: (n) => ({
    prompt: `Given ${n} items, report which value occurs most frequently.`,
    solution: "Count occurrences in a hash map, then take the key with the max count.",
  }),
  slidingWindow: (n) => ({
    prompt: `Find the smallest window in an array whose sum is at least ${n}.`,
    solution: "Grow the window until the sum qualifies, then shrink from the left while it still does.",
  }),
  caching: (n) => ({
    prompt: `Design an eviction policy for a cache holding at most ${n} entries.`,
    solution: "LRU via a hash map plus a doubly linked list gives O(1) get and put.",
  }),
};

function fallback(topic: string, seed: number) {
  return {
    prompt: `Practice problem #${seed} for ${topic}: explain the core pattern and its complexity.`,
    solution: "Restate the canonical approach for this topic in your own words.",
  };
}

export const handler = async (event: AppSyncEvent) => {
  const topic = assertValidTopic(event.arguments?.topic);
  const count = safeInt(event.arguments?.count, 1, 20);

  const make = TEMPLATES[topic] ?? ((seed: number) => fallback(topic, seed));

  return Array.from({ length: count }, (_, i) => {
    const seed = i + 1;
    const { prompt, solution } = make(seed);
    return {
      id: `gen-${topic}-${Date.now()}-${seed}`,
      topic,
      difficulty: 1,
      prompt,
      solution,
      code: "",
      language: "",
      timeComplexity: "n/a",
      spaceComplexity: "n/a",
      source: "Generated",
      license: "AlgoRhythm",
    };
  });
};
