---
type: chore
status: draft
priority: high
created: 2026-03-23
updated: 2026-03-23
tags: ["bug", "bedrock", "ai", "infrastructure"]
related: ["02-api-foundation", "04-hand-input-parsing", "05-player-tracking", "06-search-filtering"]
---

# Bedrock Region Routing Bug Fix

## Problem Statement

The Bedrock SDK is routing inference profile API calls to `us-east-1` instead of the configured `us-west-2` region, causing all AI features to fail with 403 AccessDenied errors. This blocks hand parsing, AI natural language search, and player summary generation.

## Current Behavior

When the API attempts to invoke the Bedrock model:
- Environment variable `AWS_REGION=us-west-2` is set
- Model ID: `us.anthropic.claude-sonnet-4-6` (inference profile)
- SDK creates request to: `arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-sonnet-4-6`
- IAM policy denies because it only allows `us-west-2` resources

**Error:**
```
AccessDeniedException: User: arn:aws:sts::446490546198:assumed-role/lolfold-dev-ecs-task/[task-id]
is not authorized to perform: bedrock:InvokeModel on resource:
arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-sonnet-4-6
because no identity-based policy allows the bedrock:InvokeModel action
```

## Expected Behavior

- SDK should use `us-west-2` region for all Bedrock API calls
- Inference profile calls should resolve to the correct regional endpoint
- All AI-powered features should work correctly

## Success Criteria

- [ ] Hand parsing works (`POST /api/hands/parse` returns parsed data, not 502)
- [ ] AI search works (`POST /api/hands/search` with NL query returns results)
- [ ] Player summaries work (AI-generated summaries appear in player profiles)
- [ ] No 403 AccessDenied errors in CloudWatch logs for Bedrock calls
- [ ] Bedrock SDK logs show `us-west-2` endpoint, not `us-east-1`

## Scope

### In Scope
- Debug BedrockRuntimeClient region configuration
- Test alternative model ID formats (inference profile vs. foundation model)
- Add explicit region configuration if needed
- Update IAM policy if cross-region access is intentional behavior
- Document root cause and solution

### Out of Scope
- Changing the model (must remain Claude Sonnet 4.6 or equivalent)
- Adding retry logic or fallback mechanisms
- Performance optimization

## Dependencies

- Specs 02, 04, 05, 06 (all use Bedrock service)
- ECS task role IAM policy
- BedrockRuntimeClient SDK configuration

## Assumptions

- The AWS SDK version is current and not the source of the issue
- The inference profile ID is valid and available in us-west-2
- The IAM policy should NOT allow us-east-1 access (principle of least privilege)

## Investigation Steps

1. **Verify SDK Configuration**
   - Check `src/services/bedrock.ts` BedrockRuntimeClient initialization
   - Confirm region is explicitly passed: `new BedrockRuntimeClient({ region: config.aws.region })`
   - Verify `config.aws.region` value at runtime

2. **Test Model ID Formats**
   - Current: `us.anthropic.claude-sonnet-4-6` (inference profile)
   - Alternative: `anthropic.claude-3-5-sonnet-20240620-v1:0` (foundation model)
   - Test if foundation model IDs route correctly to us-west-2

3. **Check Converse API Call**
   - Verify modelId passed to ConverseCommand
   - Check if SDK rewrites inference profile ARNs incorrectly
   - Add debug logging for actual request endpoint

4. **Review SDK Documentation**
   - Confirm expected behavior for inference profiles
   - Check if inference profiles have special routing rules
   - Look for known issues in AWS SDK for JavaScript v3

## Possible Solutions

### Option 1: Use Foundation Model ID (Quickest)
Replace `us.anthropic.claude-sonnet-4-6` with `anthropic.claude-3-5-sonnet-20240620-v1:0` in environment variable. Foundation models have explicit regional endpoints.

**Pros:** Immediate fix, no SDK debugging needed
**Cons:** Loses inference profile benefits (if any), older model version

### Option 2: Explicit Region Override
Update BedrockRuntimeClient initialization and ConverseCommand calls to explicitly set region.

**Pros:** Keeps inference profile, fixes root cause
**Cons:** May require SDK version upgrade or code changes

### Option 3: Multi-Region IAM Policy (Not Recommended)
Add `arn:aws:bedrock:us-east-1::foundation-model/*` to IAM policy.

**Pros:** Works around SDK behavior
**Cons:** Violates least-privilege, doesn't fix root cause, allows unexpected cross-region calls

### Option 4: Update to Latest SDK
Upgrade `@aws-sdk/client-bedrock-runtime` to latest version.

**Pros:** May fix known bug
**Cons:** Requires testing, deployment, may not solve issue

## References

- [AWS Bedrock Inference Profiles](https://docs.aws.amazon.com/bedrock/latest/userguide/inference-profiles.html)
- [AWS SDK JavaScript v3 - BedrockRuntimeClient](https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/client/bedrock-runtime/)
- Current IAM Policy: `modules/ai/main.tf`
- Bedrock Service Code: `lolfold-api/src/services/bedrock.ts`
- CloudWatch Log Group: `/ecs/lolfold-dev-api`
