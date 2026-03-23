# Org Standards

## GitHub

- **Organization:** `scottlusk-slalom`
- **Repo defaults:** private, `main` branch
- **Repo creation:** `gh repo create scottlusk-slalom/<name> --private`

## AWS

- **Default region:** `us-west-2`
- **Authentication:** AWS CLI SSO (`aws sso login`)

## Infrastructure

- **IaC standard:** Terraform
- **State backend:** Determine per-project (S3 + DynamoDB typical)

## Security

### Security Group Rules

- **No quad-zero ingress.** Never use `0.0.0.0/0` for inbound rules.
- **Allowed inbound sources:**
  - VPC CIDR block (for internal service-to-service traffic)
  - Scott's personal IP (for development/testing access)
- Outbound rules can be permissive where appropriate, but prefer scoping to known destinations.
