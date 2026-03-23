---
type: bug
status: draft
priority: high
created: 2026-03-23
updated: 2026-03-23
tags: ["bug", "bedrock", "ai"]
related: ["04-hand-input-parsing", "05-player-tracking", "06-search-filtering"]
---

# Upgrade to Claude 4 on Bedrock

## Problem Statement

Claude 4+ models on Bedrock require inference profile IDs (e.g. `us.anthropic.claude-sonnet-4-6`) instead of direct foundation model IDs. The Node.js SDK (`@aws-sdk/client-bedrock-runtime@^3.700.0`) misroutes inference profile requests to `us-east-1` instead of `us-west-2`, causing 403 errors. The app currently falls back to Claude 3.5 Sonnet v2, which is significantly less capable.

**Confirmed:** The AWS CLI handles inference profiles correctly in us-west-2. The issue is SDK-specific.

## Success Criteria

- [ ] API uses a Claude 4+ model (Sonnet 4.6 preferred)
- [ ] Hand parsing, AI search, and player summaries all work
- [ ] No AccessDenied or region routing errors in CloudWatch logs

## Fix Options (Ranked)

### A: Full Inference Profile ARN (Safest)
Pass the complete ARN as the model ID so the SDK cannot misroute:
`arn:aws:bedrock:us-west-2:446490546198:inference-profile/us.anthropic.claude-sonnet-4-6`

### B: Upgrade AWS SDK
Bump `@aws-sdk/client-bedrock-runtime` to latest. Routing may be fixed in newer releases.

### C: Explicit Endpoint URL
Set `endpoint` on BedrockRuntimeClient to `https://bedrock-runtime.us-west-2.amazonaws.com`.

Try A first. If it doesn't work, combine with B.

## Repos
- **lolfold-api**: `src/services/bedrock.ts`, `src/config/index.ts`, `package.json`
- **lolfold-infra**: `modules/compute/main.tf` (BEDROCK_MODEL_ID env var)
