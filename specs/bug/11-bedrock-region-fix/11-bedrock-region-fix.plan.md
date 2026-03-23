# Execution Plan: Bedrock Region Routing Fix

## Approach

Start with the quickest solution (Option 1: foundation model ID) to unblock AI features, then investigate root cause for long-term fix if needed. This follows fail-fast principles—get a working system first, optimize second.

## Key Decisions & Constraints

1. **Quick Win First:** Use foundation model ID `anthropic.claude-3-5-sonnet-20240620-v1:0` to validate hypothesis before deeper investigation
2. **No Code Changes (Initially):** Test via environment variable change only—redeploy ECS task definition
3. **Preserve Evidence:** Capture CloudWatch logs showing us-east-1 routing before fix for documentation
4. **Rollback Plan:** Keep inference profile ID documented for future retry if foundation model has limitations

## Milestones

### 1. Validate Current State
- Capture CloudWatch logs showing us-east-1 region in error
- Confirm IAM policy denies us-east-1 (expected behavior)
- Document exact model ID currently in use: `us.anthropic.claude-sonnet-4-6`

### 2. Test Foundation Model ID
- Update ECS task definition environment: `BEDROCK_MODEL_ID=anthropic.claude-3-5-sonnet-20240620-v1:0`
- Apply terraform changes
- Force ECS service redeployment
- Test hand parsing: `POST /api/hands/parse` with sample input
- Verify success or capture new error state

### 3. Validate Fix
- Test all AI features: hand parsing, AI search, player summaries
- Confirm CloudWatch logs show us-west-2 endpoint
- Verify no 403 errors in logs
- Performance check: response times acceptable (< 5s for parse)

### 4. Document Root Cause (If Fixed)
- Update DEPLOYMENT.md with solution applied
- Note if inference profiles have known region routing issues
- Document recommended model ID for future deployments

### 5. Investigate Deeper (If Foundation Model Fails)
- Clone lolfold-api locally
- Add debug logging to BedrockRuntimeClient instantiation
- Inspect ConverseCommand request object before send
- Check SDK version against known issues
- Test explicit region override in code

## Affected Systems

- **lolfold-infra:** Task definition environment variables (terraform)
- **lolfold-api:** Runtime Bedrock client configuration (no code changes unless Option 2 needed)
- **ECS Service:** Requires redeployment to pick up new task definition

## Risks

- **Foundation model may not support all features:** Inference profiles may offer extended context or routing benefits
- **Model version difference:** v1:0 is older than 4.6, but should be functionally equivalent for POC
- **Time to test:** Each deployment takes ~2 minutes (task start + health checks)

## Notes

- The inference profile `us.anthropic.claude-sonnet-4-6` is a valid ID returned by `aws bedrock list-inference-profiles`
- The IAM policy correctly includes both foundation models and inference profiles in us-west-2
- The SDK may have a bug where inference profile ARNs are rewritten to a default region (us-east-1)
- If foundation model works, consider filing AWS support case about inference profile routing behavior
