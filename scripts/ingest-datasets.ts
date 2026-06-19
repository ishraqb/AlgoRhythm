/**
 * Pulls free, attribution-licensed content into AlgoRhythm's card format:
 *   - MBPP (CC-BY-4.0) for algorithm problems
 *   - system-design-primer (CC BY 4.0) for system-design concepts
 *
 * Both hosts are fixed constants below (Hugging Face + GitHub raw); no part of
 * the request target comes from user input.
 *
 * Output: out/cards.generated.json, later loaded by seed-dynamo.ts.
 */
import { writeFileSync, mkdirSync } from "fs";
import { join } from "path";

interface Card {
  id: string;
  topic: string;
  difficulty: number;
  prompt: string;
  solution: string;
  code: string;
  language: string;
  timeComplexity: string;
  spaceComplexity: string;
  source: string;
  license: string;
}

const MBPP_ROWS_URL =
  "https://datasets-server.huggingface.co/rows?dataset=google-research-datasets%2Fmbpp&config=full&split=train&offset=0&length=100";
const SDP_README_URL =
  "https://raw.githubusercontent.com/donnemartin/system-design-primer/master/README.md";

const MBPP_LIMIT = 60;
const SDP_LIMIT = 20;

// Rough keyword routing so generated cards land on a sensible topic.
const ALGO_KEYWORDS: Array<[string, RegExp]> = [
  ["hashMaps", /\b(dictionary|hash|frequency|count|map)\b/i],
  ["slidingWindow", /\b(window|substring|consecutive|subarray)\b/i],
  ["twoPointers", /\b(pair|two|sorted|reverse)\b/i],
  ["trees", /\b(tree|node|binary)\b/i],
  ["graphs", /\b(graph|path|island|grid|matrix)\b/i],
  ["recursion", /\b(recursi|factorial|permutation|combination)\b/i],
  ["dynamicProgramming", /\b(maximum|minimum|longest|number of ways|fibonacci)\b/i],
  ["bitManipulation", /\b(bit|binary|xor|odd|even)\b/i],
];

function guessAlgoTopic(text: string): string {
  for (const [topic, pattern] of ALGO_KEYWORDS) {
    if (pattern.test(text)) return topic;
  }
  return "arrays";
}

async function fetchMbpp(): Promise<Card[]> {
  const res = await fetch(MBPP_ROWS_URL);
  if (!res.ok) throw new Error(`MBPP fetch failed: ${res.status}`);
  const data = (await res.json()) as { rows: Array<{ row: Record<string, unknown> }> };

  return data.rows.slice(0, MBPP_LIMIT).map((entry) => {
    const row = entry.row;
    const text = String(row.text ?? row.prompt ?? "").trim();
    const code = String(row.code ?? "").trim();
    const taskId = String(row.task_id ?? Math.random().toString(36).slice(2));
    return {
      id: `mbpp-${taskId}`,
      topic: guessAlgoTopic(text),
      difficulty: 1,
      prompt: text,
      solution: "Reference implementation:",
      code,
      language: "Python",
      timeComplexity: "n/a",
      spaceComplexity: "n/a",
      source: "MBPP",
      license: "CC-BY-4.0",
    };
  });
}

// Map system-design-primer section headings onto our topics.
const SDP_TOPICS: Array<[string, RegExp]> = [
  ["loadBalancing", /load balanc/i],
  ["caching", /cache|caching/i],
  ["sharding", /shard|partition|federation/i],
  ["capTheorem", /\bcap\b|consistency|availability/i],
  ["microservices", /microservice|service discovery/i],
  ["rateLimiting", /rate limit/i],
  ["messageQueues", /message queue|kafka|rabbitmq|pub.?sub|asynchron/i],
];

function guessSystemTopic(heading: string): string | null {
  for (const [topic, pattern] of SDP_TOPICS) {
    if (pattern.test(heading)) return topic;
  }
  return null;
}

async function fetchSystemDesign(): Promise<Card[]> {
  const res = await fetch(SDP_README_URL);
  if (!res.ok) throw new Error(`system-design-primer fetch failed: ${res.status}`);
  const markdown = await res.text();

  const cards: Card[] = [];
  // Split on level-2 headings and keep the text directly under each.
  const sections = markdown.split(/\n##\s+/).slice(1);
  for (const section of sections) {
    const [headingLine, ...rest] = section.split("\n");
    const heading = headingLine.replace(/[#*`]/g, "").trim();
    const topic = guessSystemTopic(heading);
    if (!topic) continue;

    const body = rest
      .join("\n")
      .replace(/<[^>]+>/g, "")
      .split("\n")
      .map((l) => l.trim())
      .filter((l) => l.length > 0 && !l.startsWith("#") && !l.startsWith("!["));
    const solution = body.slice(0, 4).join(" ").slice(0, 600);
    if (solution.length < 40) continue;

    cards.push({
      id: `sdp-${topic}-${cards.length}`,
      topic,
      difficulty: 2,
      prompt: `Explain the key idea and trade-offs of: ${heading}`,
      solution,
      code: "",
      language: "",
      timeComplexity: "n/a",
      spaceComplexity: "n/a",
      source: "system-design-primer",
      license: "CC BY 4.0",
    });
    if (cards.length >= SDP_LIMIT) break;
  }
  return cards;
}

async function main() {
  const cards: Card[] = [];

  try {
    const mbpp = await fetchMbpp();
    console.log(`MBPP: ${mbpp.length} cards`);
    cards.push(...mbpp);
  } catch (err) {
    console.warn("Skipping MBPP:", (err as Error).message);
  }

  try {
    const sdp = await fetchSystemDesign();
    console.log(`system-design-primer: ${sdp.length} cards`);
    cards.push(...sdp);
  } catch (err) {
    console.warn("Skipping system-design-primer:", (err as Error).message);
  }

  const outDir = join(__dirname, "out");
  mkdirSync(outDir, { recursive: true });
  const outPath = join(outDir, "cards.generated.json");
  writeFileSync(outPath, JSON.stringify(cards, null, 2));
  console.log(`Wrote ${cards.length} cards to ${outPath}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
