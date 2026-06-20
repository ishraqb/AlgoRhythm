/**
 * Turns the CDK deploy outputs into the app's AppConfig.plist. Run after
 * `cdk deploy --outputs-file cdk-outputs.json`. The plist is gitignored, so the
 * live endpoint and pool IDs never land in source control.
 */
import { readFileSync, writeFileSync } from "fs";
import { join } from "path";

const STACK_NAME = process.env.STACK_NAME ?? "AlgoRhythmStack";

function escapeXml(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

function main() {
  const outputsPath = join(__dirname, "..", "backend", "cdk-outputs.json");
  const raw = JSON.parse(readFileSync(outputsPath, "utf-8")) as Record<
    string,
    Record<string, string>
  >;

  const outputs = raw[STACK_NAME];
  if (!outputs) {
    throw new Error(`No outputs for stack ${STACK_NAME} in cdk-outputs.json`);
  }

  const region = outputs.Region ?? "us-east-1";
  const clientId = outputs.UserPoolClientId ?? "";
  const endpoint = outputs.GraphQLEndpoint ?? "";

  const plist = `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
\t<key>Region</key>
\t<string>${escapeXml(region)}</string>
\t<key>UserPoolClientId</key>
\t<string>${escapeXml(clientId)}</string>
\t<key>AppSyncEndpoint</key>
\t<string>${escapeXml(endpoint)}</string>
</dict>
</plist>
`;

  const dest = join(
    __dirname,
    "..",
    "ios",
    "AlgoRhythm",
    "Resources",
    "AppConfig.plist"
  );
  writeFileSync(dest, plist);
  console.log(`Wrote ${dest}`);
}

main();
