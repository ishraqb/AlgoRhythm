# AlgoRhythm

A native iOS app for technical-interview prep with a swipe-to-study flashcard
interface, an adaptive difficulty engine, and a serverless AWS backend.

- **iOS app** (`ios/`): Swift / SwiftUI. Swipe right to mark a card mastered,
  left to flag it for review; tap to flip for the solution, code, and
  time/space complexity. Haptics and an optional rapid-fire tick keep sessions
  focused.
- **Backend** (`backend/`): AWS CDK (TypeScript) defining Cognito (email/password
  auth), AppSync (GraphQL), DynamoDB, and Lambda resolvers.
- **Scripts** (`scripts/`): pull free, attribution-licensed content (MBPP,
  system-design-primer) and seed it into DynamoDB.

For step-by-step run and deploy instructions, see [DEPLOYMENT.md](DEPLOYMENT.md).

## Architecture

```
SwiftUI app  ──(Cognito email/password)──▶  Cognito User Pool
     │
     └──(GraphQL + Cognito token)──▶  AppSync ──▶ Lambda resolvers ──▶ DynamoDB
                                                  (PK User_ID / SK Topic_ID)
```

The app is offline-first: the bundled `questions.json` always works with no
network. Only user performance syncs to the cloud, and the server derives the
owner from the verified token, so users can only read/write their own data.

## Prerequisites

- Xcode 16+ (full app, not just Command Line Tools)
- Node.js 18+ and npm
- An AWS account with credentials configured (`aws configure`)

If Xcode was just installed, finish its component setup once:

```bash
sudo xcodebuild -runFirstLaunch
xcodebuild -downloadPlatform iOS
```

## Run the iOS app

```bash
open ios/AlgoRhythm.xcodeproj
```

Pick an iPhone simulator and press Run. With no backend configured yet, the
sign-in screen offers "Continue without an account" so you can try the deck
locally. Progress stays on-device in that mode.

## Deploy the backend

```bash
cd backend
npm install
npx cdk bootstrap          # one-time per account/region
npx cdk deploy --outputs-file cdk-outputs.json
```

Then generate the app config and seed content:

```bash
cd ../scripts
npm install
npm run ingest             # downloads MBPP + system-design-primer cards
TABLE_NAME=AlgoRhythm npm run seed
npm run write-config       # writes ios/AlgoRhythm/Resources/AppConfig.plist
```

Rebuild the app in Xcode and it will use real Cognito auth and cloud sync.

To tear everything down:

```bash
cd backend && npx cdk destroy
```

## Content & licensing

- Original baseline cards are authored for AlgoRhythm.
- MBPP — CC-BY-4.0. system-design-primer (Donne Martin) — CC BY 4.0.
- Attribution is shown in-app on the Credits screen. No LeetCode scraping or
  copyrighted third-party problem text is used.

## Cost

Designed to run at $0: free personal Apple ID sideloading and AWS free-tier
services (Cognito, Lambda, AppSync, DynamoDB on-demand). No paid APIs.
