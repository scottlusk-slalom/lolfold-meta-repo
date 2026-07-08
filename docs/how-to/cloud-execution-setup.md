# Cloud Execution Setup

Step-by-step guide for enabling cloud execution mode in a derived metarepo. Cloud mode dispatches spec orchestration to AWS Bedrock AgentCore runtimes instead of running locally.

## Prerequisites

- AWS account with Bedrock AgentCore access (preview region: us-east-1)
- Existing VPC with private subnets and NAT gateway
- GitHub App (for bot identity) or Personal Access Token
- ae-harness-infra repository (separate infrastructure repo for Terraform modules)

## Steps

### 1. Deploy Harness Infrastructure

Clone and configure the infrastructure repository:

```bash
git clone git@github.com:Slalom/ae-harness-infra.git {project}-harness-infra
cd {project}-harness-infra
```

Fill `terraform.tfvars` with your values:

```hcl
project_name    = "your-project-name"
region          = "us-east-1"
vpc_id          = "vpc-xxxxx"
subnet_ids      = ["subnet-xxxxx", "subnet-yyyyy"]
github_repo     = "org/your-metarepo"
github_app_id   = "123456"  # Optional: for GitHub App auth
```

Deploy:

```bash
terraform init
terraform apply
```

Note the outputs — you'll need these values:

- `orchestrator_runtime_arn` — for the `/orchestrate` command
- `subagent_runtime_arn` — for `SUBAGENT_RUNTIME_ARN` env var
- `webhook_url` — API Gateway endpoint for GitHub webhooks
- `agent_ecr_repo` — ECR repository for agent container image

### 2. Build and Push Agent Container

From the `ae-harness-infra` repository:

```bash
./scripts/build-and-push.sh
```

This builds the agent container and pushes it to the ECR repository created by Terraform. The image includes the Claude agent runtime and dependencies needed for spec execution.

Verify the image appears in ECR:

```bash
aws ecr describe-images --repository-name {project}-harness-agent
```

### 3. Configure GitHub Webhook

Option A: Automated setup:

```bash
./scripts/setup-webhook.sh
```

Option B: Manual configuration in GitHub:

1. Navigate to your metarepo's Settings > Webhooks > Add webhook
2. Payload URL: `{webhook_url}` from Terraform output
3. Content type: `application/json`
4. Secret: Retrieve from AWS Secrets Manager:
   ```bash
   aws secretsmanager get-secret-value --secret-id {project}-harness/github-webhook-secret --query SecretString --output text
   ```
5. Events: Select individual events:
   - Pull requests
   - Issue comments
   - Pull request reviews
6. Active: Checked

### 4. Enable Session Storage (One-Time)

AgentCore preview feature for persistent filesystem across invocations. Required for session resumption on PR comments.

```bash
aws bedrock-agent-runtime enable-session-storage \
  --runtime-id {orchestrator-runtime-id} \
  --storage-type FILESYSTEM \
  --retention-days 7
```

Verify:

```bash
aws bedrock-agent-runtime describe-runtime --runtime-id {orchestrator-runtime-id} | jq '.sessionStorage'
```

### 5. Set Environment Variables

In your metarepo, configure cloud execution mode.

Option A: Project settings (`.claude/settings.local.json`):

```json
{
  "env": {
    "SUBAGENT_RUNTIME_ARN": "arn:aws:bedrock:us-east-1:123456789012:agent-runtime/XXXXXXXXXX",
    "CLAUDE_CODE_USE_BEDROCK": "1",
    "AWS_REGION": "us-east-1"
  }
}
```

Option B: Shell profile (`.zshrc` or `.bashrc`):

```bash
export SUBAGENT_RUNTIME_ARN="arn:aws:bedrock:us-east-1:123456789012:agent-runtime/XXXXXXXXXX"
export CLAUDE_CODE_USE_BEDROCK=1
export AWS_REGION=us-east-1
```

Use the `subagent_runtime_arn` value from Terraform output.

### 6. Validate

Create a test spec and dispatch to cloud:

```bash
# In your metarepo
claude /generate-spec test-cloud-execution --type feature

# Approve the spec
claude /approve specs/feature/test-cloud-execution

# Orchestrate to cloud
claude /orchestrate specs/feature/test-cloud-execution
```

Verify the following:

1. **PR created:** Check GitHub for a new PR with labels:
   - `session-id:{33-char-id}`
   - `spec-key:test-cloud-execution`
   - `repo:{repo-name}`

2. **Webhook fires on comment:** Add a PR comment like `claude continue` or `@claude what's the status?`

3. **Orchestrator resumes:** Check CloudWatch Logs for the orchestrator Lambda:
   ```bash
   aws logs tail /aws/lambda/{project}-harness-orchestrator --follow
   ```

4. **Sub-agent dispatches:** Verify sub-agent invocations in CloudWatch Logs:
   ```bash
   aws logs tail /aws/lambda/{project}-harness-subagent --follow
   ```

## Troubleshooting

### Webhook Not Firing

- Check API Gateway logs:
  ```bash
  aws logs tail /aws/apigateway/{api-id} --follow
  ```
- Verify webhook secret matches GitHub configuration:
  ```bash
  aws secretsmanager get-secret-value --secret-id {project}-harness/github-webhook-secret
  ```
- Test webhook delivery in GitHub Settings > Webhooks > Recent Deliveries

### Session Not Resuming

- Verify session ID format: Must be 33+ characters (e.g., `sess_abcd1234...`)
- Check PR labels contain `session-id:{id}`
- Review orchestrator Lambda logs for session retrieval errors
- Confirm session storage is enabled (see step 4)

### Auth Failures

- Verify GitHub App installation: Settings > GitHub Apps > {your-app} > Install App
- Check Secrets Manager values:
  ```bash
  aws secretsmanager list-secrets --filters Key=name,Values={project}-harness
  ```
- Ensure IAM role for orchestrator has `secretsmanager:GetSecretValue` permission

### Sub-Agent Not Dispatching

- Verify `SUBAGENT_RUNTIME_ARN` is set in your environment
- Check orchestrator logs for invocation errors
- Confirm sub-agent runtime exists:
  ```bash
  aws bedrock-agent-runtime describe-runtime --runtime-id {subagent-runtime-id}
  ```
- Verify IAM role has `bedrock:InvokeAgent` permission

### Container Image Issues

- Re-build and push:
  ```bash
  cd {project}-harness-infra
  ./scripts/build-and-push.sh
  ```
- Verify image digest matches runtime configuration:
  ```bash
  aws bedrock-agent-runtime describe-runtime --runtime-id {runtime-id} | jq '.containerImage'
  ```

## Next Steps

- Configure repo-specific execution settings in `repos/{repo}/_loop-config.yaml`
- Set up notification channels (Slack, email) for PR status updates
- Review `specifics/transport/github-prs.md` for protocol details
- Customize agent container with project-specific tools (see `ae-harness-infra/docker/`)

## Reference

- [ae-harness-infra README](https://github.com/Slalom/ae-harness-infra/blob/main/README.md)
- [AgentCore Documentation](https://docs.aws.amazon.com/bedrock/latest/userguide/agents.html)
- [Transport Protocol](../../specifics/transport/github-prs.md)
- [Cloud Execution Architecture](../../specifics/README.md)
