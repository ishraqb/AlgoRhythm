import { BatchWriteCommand } from "@aws-sdk/lib-dynamodb";
import { ddb, TABLE_NAME, assertValidTopic, safeInt } from "./shared";

interface PerformanceInput {
  topicId: string;
  tier: number;
  mastered: number;
  reviewed: number;
  streak: number;
}

interface AppSyncEvent {
  arguments: { records: PerformanceInput[] };
  identity?: { sub?: string };
}

// The owner is taken from the verified Cognito token, never from the request
// body, so a caller can only ever write to their own partition.
export const handler = async (event: AppSyncEvent) => {
  const userId = event.identity?.sub;
  if (!userId) {
    throw new Error("Unauthorized");
  }

  const records = Array.isArray(event.arguments?.records)
    ? event.arguments.records.slice(0, 25) // BatchWrite caps at 25 items
    : [];

  try {
    const sanitized = records.map((r) => {
      const topicId = assertValidTopic(r.topicId);
      return {
        topicId,
        tier: safeInt(r.tier, 0, 4),
        mastered: safeInt(r.mastered, 0, 1_000_000),
        reviewed: safeInt(r.reviewed, 0, 1_000_000),
        streak: safeInt(r.streak, -1000, 1000),
      };
    });

    if (sanitized.length > 0) {
      await ddb.send(
        new BatchWriteCommand({
          RequestItems: {
            [TABLE_NAME]: sanitized.map((r) => ({
              PutRequest: {
                Item: {
                  PK: userId,
                  SK: `PERF#${r.topicId}`,
                  topicId: r.topicId,
                  tier: r.tier,
                  mastered: r.mastered,
                  reviewed: r.reviewed,
                  streak: r.streak,
                  updatedAt: new Date().toISOString(),
                },
              },
            })),
          },
        })
      );
    }

    return sanitized;
  } catch (err) {
    console.error("updateUserPerformanceTrack failed", err);
    throw new Error("Unable to save progress");
  }
};
