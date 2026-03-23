# Execution Plan: Upgrade to Claude 4 on Bedrock

## Approach

Try fix Option A (full inference profile ARN) first — it's explicit and doesn't depend on SDK version. If it fails, upgrade the SDK (Option B) and retry.

## Key Decisions & Constraints

- Current workaround: `anthropic.claude-3-5-sonnet-20241022-v2:0` (direct invocation, works but old model)
- Target: `us.anthropic.claude-sonnet-4-6` via inference profile
- No IAM changes needed — policy already allows inference profiles in us-west-2
- Avoid multi-region IAM workarounds (violates least-privilege)

## Milestones

### 1. Try Full ARN
- Update `BEDROCK_MODEL_ID` env var to `arn:aws:bedrock:us-west-2:446490546198:inference-profile/us.anthropic.claude-sonnet-4-6`
- Deploy and test hand parsing
- If it works, done

### 2. If ARN Fails: Upgrade SDK
- Bump `@aws-sdk/client-bedrock-runtime` to latest in `package.json`
- Rebuild Docker image, push to ECR, redeploy
- Test with short inference profile ID: `us.anthropic.claude-sonnet-4-6`

### 3. Validate
- Test all AI features (parse, search, summaries)
- Confirm no errors in CloudWatch logs

## Affected Systems
- lolfold-api (config or package.json)
- lolfold-infra (env var in task definition)

## Risks
- Full ARN format may not be accepted by Converse API
- SDK upgrade could introduce breaking changes in other AWS calls
