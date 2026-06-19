import { QueryCommand } from "@aws-sdk/lib-dynamodb";
import { ddb, TABLE_NAME, CARDS_PARTITION, assertValidTopic } from "./shared";

interface AppSyncEvent {
  arguments: { topic: string };
}

// Cards for a topic live under a single partition keyed by SK "<topic>#<id>".
// The query is fully parameterized via ExpressionAttributeValues.
export const handler = async (event: AppSyncEvent) => {
  try {
    const topic = assertValidTopic(event.arguments?.topic);

    const result = await ddb.send(
      new QueryCommand({
        TableName: TABLE_NAME,
        KeyConditionExpression: "PK = :pk AND begins_with(SK, :prefix)",
        ExpressionAttributeValues: {
          ":pk": CARDS_PARTITION,
          ":prefix": `${topic}#`,
        },
      })
    );

    return (result.Items ?? []).map((item) => ({
      id: item.id,
      topic: item.topic,
      difficulty: item.difficulty,
      prompt: item.prompt,
      solution: item.solution,
      code: item.code ?? "",
      language: item.language ?? "",
      timeComplexity: item.timeComplexity ?? "",
      spaceComplexity: item.spaceComplexity ?? "",
      source: item.source ?? "",
      license: item.license ?? "",
    }));
  } catch (err) {
    // Log server-side detail; hand the client a generic message.
    console.error("getCardsByTopic failed", err);
    throw new Error("Unable to load cards");
  }
};
