/**
 * Loads the card catalog into DynamoDB. Cards live under a single partition
 * (PK = "CARDS") with SK = "<topic>#<id>" so the getCardsByTopic resolver can
 * range-query one topic at a time.
 *
 * Sources: the app's bundled baseline deck plus anything ingest-datasets.ts
 * produced. Run with valid AWS credentials in the environment.
 */
import { readFileSync, existsSync } from "fs";
import { join } from "path";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, BatchWriteCommand } from "@aws-sdk/lib-dynamodb";

interface Card {
  id: string;
  topic: string;
  difficulty: number | string;
  prompt: string;
  solution: string;
  code: string;
  language: string;
  timeComplexity: string;
  spaceComplexity: string;
  source: string;
  license: string;
}

const TABLE_NAME = process.env.TABLE_NAME ?? "AlgoRhythm";
const REGION = process.env.AWS_REGION ?? "us-east-1";

const ddb = DynamoDBDocumentClient.from(new DynamoDBClient({ region: REGION }), {
  marshallOptions: { removeUndefinedValues: true },
});

const DIFFICULTY_RANK: Record<string, number> = {
  intro: 0,
  easy: 1,
  medium: 2,
  hard: 3,
  expert: 4,
};

function normalizeDifficulty(value: number | string): number {
  if (typeof value === "number") return value;
  return DIFFICULTY_RANK[value.toLowerCase()] ?? 1;
}

function loadCards(): Card[] {
  const baselinePath = join(
    __dirname,
    "..",
    "ios",
    "AlgoRhythm",
    "Resources",
    "questions.json"
  );
  const generatedPath = join(__dirname, "out", "cards.generated.json");

  const cards: Card[] = JSON.parse(readFileSync(baselinePath, "utf-8"));
  if (existsSync(generatedPath)) {
    const generated: Card[] = JSON.parse(readFileSync(generatedPath, "utf-8"));
    cards.push(...generated);
  }
  return cards;
}

async function main() {
  const cards = loadCards();
  console.log(`Seeding ${cards.length} cards into ${TABLE_NAME} (${REGION})`);

  const items = cards.map((card) => ({
    PutRequest: {
      Item: {
        PK: "CARDS",
        SK: `${card.topic}#${card.id}`,
        ...card,
        difficulty: normalizeDifficulty(card.difficulty),
      },
    },
  }));

  // BatchWrite handles 25 items per call.
  for (let i = 0; i < items.length; i += 25) {
    const batch = items.slice(i, i + 25);
    await ddb.send(new BatchWriteCommand({ RequestItems: { [TABLE_NAME]: batch } }));
    console.log(`  wrote ${Math.min(i + 25, items.length)}/${items.length}`);
  }

  console.log("Done.");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
