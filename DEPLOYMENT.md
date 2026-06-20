# Deployment & Run Guide

This walks through running AlgoRhythm two ways:

1. **Local only** — run the app in the iOS Simulator with the bundled deck. No
   AWS account or network needed. Good for trying the UI in a minute.
2. **Full stack** — deploy the serverless AWS backend (Cognito + AppSync +
   DynamoDB + Lambda), seed the card catalog, and point the app at it for real
   accounts and cloud sync.

---

## Prerequisites

| Tool | Version | Needed for |
| --- | --- | --- |
| Xcode | 16+ (full app, not just Command Line Tools) | iOS app |
| Node.js | 18+ and npm | backend + scripts |
| AWS CLI | configured with `aws configure` | full-stack deploy only |

If Xcode was just installed, finish its one-time component setup:

```bash
sudo xcodebuild -runFirstLaunch
xcodebuild -downloadPlatform iOS
```

---

## 1. Run locally (no backend)

### Option A — Xcode (easiest)

```bash
open ios/AlgoRhythm.xcodeproj
```

1. Pick an iPhone simulator from the device menu at the top.
2. Press the ▶ Run button (or `Cmd-R`).
3. On the sign-in screen, tap **Continue as guest** to jump straight into the
   deck. Progress is saved on-device in this mode.

### Option B — Command line

Build for the simulator, install, and launch:

```bash
cd ios

# Build (uses -target to avoid a CLI-only scheme-resolution quirk; see Troubleshooting)
xcodebuild \
  -project AlgoRhythm.xcodeproj \
  -target AlgoRhythm \
  -configuration Debug \
  -sdk iphonesimulator \
  -arch arm64 \
  CODE_SIGNING_ALLOWED=NO \
  SYMROOT="$PWD/build" \
  build

# Boot a simulator (any available iPhone), then install + launch
xcrun simctl boot "iPhone 16 Pro" 2>/dev/null; open -a Simulator
xcrun simctl install booted "build/Debug-iphonesimulator/AlgoRhythm.app"
xcrun simctl launch booted com.algorhythm.app
```

> Run `xcrun simctl list devices available` to see the simulator names you have.

---

## 2. Full-stack deploy (AWS backend)

### Step 1 — Configure AWS credentials

```bash
aws configure        # access key, secret, default region (e.g. us-east-1)
aws sts get-caller-identity   # sanity check: should print your account
```

Use an IAM user/role with permissions to create the resources below. Everything
fits in the AWS free tier.

### Step 2 — Deploy the stack

```bash
cd backend
npm install
npx cdk bootstrap                              # one-time per account/region
npx cdk deploy --outputs-file cdk-outputs.json
```

This provisions (stack name `AlgoRhythmStack`):

- **DynamoDB** table `AlgoRhythm` (on-demand)
- **Cognito** user pool with email/password sign-up
- **AppSync** GraphQL API authorized by Cognito
- **Lambda** resolvers (`getCardsByTopic`, `updateUserPerformanceTrack`,
  `generateCards`)

The deploy writes endpoint and pool IDs to `backend/cdk-outputs.json` (gitignored).

### Step 3 — Seed content and generate app config

```bash
cd ../scripts
npm install
npm run ingest                 # downloads MBPP + system-design-primer cards into out/
TABLE_NAME=AlgoRhythm npm run seed   # loads baseline + ingested cards into DynamoDB
npm run write-config           # writes ios/AlgoRhythm/Resources/AppConfig.plist
```

`write-config` reads `backend/cdk-outputs.json` and emits `AppConfig.plist`
(also gitignored) with the live `Region`, `UserPoolClientId`, and
`AppSyncEndpoint`.

### Step 4 — Rebuild the app

Re-run the app from Xcode (or the CLI build above). Because `AppConfig.plist` is
now present, the sign-in screen uses **real Cognito accounts** and performance
syncs to DynamoDB. The "Continue as guest" option still works for local-only use.

---

## Verify it's working

```bash
# Cards landed in DynamoDB
aws dynamodb scan --table-name AlgoRhythm --select COUNT

# Stack outputs (endpoint + pool IDs)
cat backend/cdk-outputs.json
```

In the app: create an account, confirm with the emailed code, swipe a few cards,
then check the **Progress** tab. Re-launching should keep your synced progress.

---

## Tear down

Remove all AWS resources so nothing keeps running:

```bash
cd backend
npx cdk destroy
```

Optionally delete the generated local files:

```bash
rm -f backend/cdk-outputs.json ios/AlgoRhythm/Resources/AppConfig.plist
```

---

## Troubleshooting

**`Scheme AlgoRhythm is not currently configured for the build action` (CLI).**
The command-line `xcodebuild` sometimes resolves an empty auto-generated scheme.
Build the target directly instead of the scheme: use `-target AlgoRhythm`
(as in Option B). Running from the Xcode GUI is unaffected.

**`actool` / "No available simulator runtimes".**
Install a simulator runtime once: `xcodebuild -downloadPlatform iOS`.

**`npx cdk bootstrap` fails with credentials error.**
Confirm `aws sts get-caller-identity` works and your default region is set.

**Sign-in fails / no guest option.**
If `AppConfig.plist` is missing, the app runs local-only and shows
"Continue as guest". If it's present but points at a torn-down stack, delete it
(`rm ios/AlgoRhythm/Resources/AppConfig.plist`) and rebuild for local mode.

**Seed wrote 0 cards.**
Run `npm run ingest` before `npm run seed`, and make sure `TABLE_NAME` matches
the deployed table (`AlgoRhythm`).

---

## Cost

Designed to run at **$0**: local simulator builds need no paid Apple Developer
account, and the AWS services used (Cognito, Lambda, AppSync, DynamoDB on-demand)
stay within the free tier for this workload. No paid third-party APIs.
