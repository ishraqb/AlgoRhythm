import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient } from "@aws-sdk/lib-dynamodb";

export const TABLE_NAME = process.env.TABLE_NAME ?? "";
export const CARDS_PARTITION = "CARDS";

const base = new DynamoDBClient({});
export const ddb = DynamoDBDocumentClient.from(base, {
  marshallOptions: { removeUndefinedValues: true },
});

// Allowlist of valid topic IDs. User-supplied topic strings are checked against
// this before they're ever used to build a key, so nothing arbitrary reaches
// DynamoDB.
export const TOPICS = new Set<string>([
  "arrays",
  "hashMaps",
  "twoPointers",
  "slidingWindow",
  "trees",
  "graphs",
  "recursion",
  "dynamicProgramming",
  "bitManipulation",
  "scalability",
  "loadBalancing",
  "caching",
  "sharding",
  "capTheorem",
  "microservices",
  "rateLimiting",
  "messageQueues",
]);

export function assertValidTopic(topic: unknown): string {
  if (typeof topic !== "string" || !TOPICS.has(topic)) {
    throw new Error("Invalid topic");
  }
  return topic;
}

/** Clamp to a finite integer in [min, max]; rejects junk like NaN/Infinity. */
export function safeInt(value: unknown, min: number, max: number): number {
  const n = typeof value === "number" ? value : Number(value);
  if (!Number.isFinite(n)) return min;
  return Math.min(max, Math.max(min, Math.trunc(n)));
}
