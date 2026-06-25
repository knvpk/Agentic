---
name: terraform-design-guide
description: Terraform AWS infrastructure design patterns, naming conventions, module structure, IAM, Lambda, RDS, S3, and security baselines. Use when starting a new infra repo, adding a Terraform module, naming resources, writing IAM policies, setting up Lambda stubs, configuring S3 buckets, or applying security controls.
compatibility: Designed for Claude Code. Targets Terraform >= 1.14 and AWS provider ~> 6.x.
metadata:
  author: knvpk
  version: "1.2"
---

## Core Principles

1. **Module-first design** — Every non-trivial logical unit of infrastructure is a module. Root-level files wire modules together; they do not contain resource definitions beyond VPC, subnets, and routing. Modules are self-contained and reusable across projects.
2. **Checkov always passes** — Run `checkov -d .` (or `checkov -f <file>`) before every plan and apply. All findings must be resolved: either fix the misconfiguration or add an inline `#checkov:skip` with justification. No unaddressed checkov warnings are acceptable in merged code.
3. **Workspace = environment = AWS account** — One workspace per environment, one AWS account per workspace. Never share accounts across workspaces.
4. **Pre-commit hooks are mandatory** — Every repo must have `terraform fmt`, `terraform validate`, and `tflint` wired into pre-commit hooks. Code that fails any of these three must not reach a commit.

---

## Pre-commit Hooks

Every Terraform repo requires a `.pre-commit-config.yaml` with at minimum:

```yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.99.0  # pin to latest stable
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_tflint
        args:
          - --args=--config=__GIT_WORKING_DIR__/.tflint.hcl
      - id: terraform_checkov
        args:
          - --args=--quiet
```

And a `.tflint.hcl` at the repo root:

```hcl
plugin "aws" {
  enabled = true
  version = "0.40.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

config {
  format = "compact"
}
```

- `terraform fmt` — enforces canonical formatting; always auto-corrects, never skip.
- `terraform validate` — catches syntax errors and invalid references before any plan.
- `tflint` — catches AWS-specific issues (deprecated resources, invalid instance types, missing required fields) that `validate` misses.

Install hooks after cloning: `pre-commit install`.

---

## Repository Layout

```
repo-root/
├── terraform.tf          # Backend + provider version pins
├── provider.tf           # AWS provider with default_tags
├── variables.tf          # All input variables
├── locals.tf             # resource_prefix, domain
├── data.tf               # Data sources shared across root
├── outputs.tf            # Root-level outputs only
├── vpc.tf                # VPC, subnets, NAT, flow logs
├── security.tf           # Shared SGs, CloudTrail, alarms
├── <module_name>.tf      # One file per module instantiation, named after the module
└── modules/              # Reusable child modules
    └── <module>/
        ├── terraform.tf  # Required providers (no backend, no provider config)
        ├── variables.tf  # Module inputs
        └── <component>.tf  # Resources + their outputs co-located
```

**Rules:**
- Never use `main.tf` — name files after the component they contain.
- Each module is instantiated in a dedicated root-level file named `<module_name>.tf` — e.g., `module "backend"` lives in `backend.tf`, `module "auth"` in `auth.tf`. Never group multiple module calls into a single file.
- Module outputs live in the same file as the resource, not a separate `outputs.tf`.
- Any pattern that would be repeated across environments or projects belongs in a module under `modules/`.
- Root `.tf` files outside `modules/` must only call modules or define top-level shared infrastructure (VPC, IGW, subnets).

---

## Terraform Version & Backend

Pin provider minor versions with `~>`. Prefer an S3 backend with encryption and DynamoDB state locking — but the choice of backend is project-specific and not mandatory.

Each module's `terraform.tf` declares `required_providers` only — no backend or provider configuration.

```hcl
# modules/<module>/terraform.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.28.0"
    }
  }
}
```

---

## Provider

```hcl
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project
      Environment = terraform.workspace
      Owner       = "team:cloud_ops"
      ManagedBy   = "Terraform"
    }
  }
}
```

Default tags apply to every resource automatically. Do not repeat `Project`, `Environment`, `Owner`, or `ManagedBy` in individual resource `tags` blocks — only add `Name` and service-specific tags there.

---

## Workspaces & Environments

| Workspace | Short | Purpose                   |
|-----------|-------|---------------------------|
| `dev`     | `d`   | Development               |
| `uat`     | `u`   | User acceptance testing   |
| `stage`   | `s`   | Staging / pre-production  |
| `prod`    | `p`   | Production                |

One AWS account per workspace. Use the full name (`dev`, `uat`, `stage`, `prod`) in workspace names and resource tags. Use short versions (`d`, `u`, `s`, `p`) only where length is constrained (e.g., S3 bucket names near the 63-char limit).

---

## Locals Pattern

Root `locals.tf`:

```hcl
locals {
  resource_prefix     = terraform.workspace == "prod" ? var.project_short : "${var.project_short}_${terraform.workspace}"
  resource_prefix_alt = terraform.workspace == "prod" ? var.project_short : "${var.project_short}-${terraform.workspace}"
  domain              = terraform.workspace == "prod" ? var.base_domain : "${terraform.workspace}.${var.base_domain}"
}
```

Module-level locals:

```hcl
locals {
  module_name = basename(path.module)   # e.g., "auth", "backend"
  api_domain  = "api.${var.domain}"
}
```

`resource_prefix` uses underscores (IAM, SG, Lambda names). `resource_prefix_alt` uses hyphens (S3 bucket names, RDS cluster identifiers).

---

## Variable Conventions

### Root variables

```hcl
variable "project"              { type = string }                              # full name, e.g., "myproject"
variable "project_short"        { type = string }                              # abbreviation, e.g., "mp"
variable "project_display_name" { type = string }                              # human label
variable "aws_region"           { type = string; default = "us-east-1" }
variable "base_domain"          { type = string }                              # e.g., "example.com"
```

Mark secrets `sensitive = true`:

```hcl
variable "gitlab_token" {
  sensitive = true
}
```

### Module universal inputs

Every module accepts these:

```hcl
variable "resource_prefix"     { type = string }   # underscore-separated, e.g., "mp_dev"
variable "resource_prefix_alt" { type = string }   # hyphen-separated, e.g., "mp-dev"
variable "domain"              { type = string }   # e.g., "dev.example.com"
variable "vpc_id"              { type = string }
variable "private_subnet_ids"  { type = list(string) }
variable "public_subnet_ids"   { type = list(string) }
```

### Service variable naming patterns

- Thresholds: `<service>_cpu_utilization_threshold`
- Retention: `<service>_logs_retention_in_days`
- Counts: `<service>_count`, `writer_count`, `reader_count`
- Admin alerts: `admin_emails`, `security_admin_emails`

---

## Resource Naming

```
${var.resource_prefix}_<service>_<component>     # underscores: SG, IAM, Lambda, CloudWatch
${var.resource_prefix_alt}-<service>-<component> # hyphens: S3, RDS cluster ID
```

Always set a `Name` tag explicitly:

```hcl
tags = {
  Name = "${var.resource_prefix}_alb_sg"
}
```

Output names follow `<resource>_<service>` order:

```hcl
output "api_sg"   {}   # not sg_api
output "pool_arn" {}
```

---

## Required Tags

| Tag           | Value                     |
|---------------|--------------------------|
| `Project`     | project name              |
| `Service`     | `api` / `cron` / `app`   |
| `Environment` | `terraform.workspace`    |
| `Tenant`      | nullable                  |
| `Owner`       | team identifier           |
| `ManagedBy`   | `Terraform`               |

A Resource Group is mandatory per tenant to enable cost/resource filtering.

---

## Module Instantiation

```hcl
module "backend" {
  source              = "./modules/backend"
  resource_prefix     = local.resource_prefix
  resource_prefix_alt = local.resource_prefix_alt
  domain              = local.domain
  hosted_zone_id      = aws_route53_zone.self.zone_id
  vpc_id              = aws_vpc.self.id
  private_subnet_ids  = aws_subnet.private[*].id
  public_subnet_ids   = aws_subnet.public[*].id

  db_sg_id   = module.db.db_sg
  parameters = {
    DB_HOST = module.db.cluster_endpoint
    DB_NAME = module.db.cluster_database_name
  }
}
```

Pass secrets as maps of SSM parameter ARNs rather than raw values.

---

## IAM Patterns

Always use `data.aws_iam_policy_document` — never `jsonencode()` for policies. This applies to both trust policies (`assume_role_policy`) and permission policies.

```hcl
data "aws_iam_policy_document" "example_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "example" {
  name               = "${var.resource_prefix}_${local.module_name}_example_role"
  assume_role_policy = data.aws_iam_policy_document.example_assume.json
}

data "aws_iam_policy_document" "example" {
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_policy" "example" {
  name   = "${var.resource_prefix}_${local.module_name}_example_policy"
  policy = data.aws_iam_policy_document.example.json
}

resource "aws_iam_role_policy_attachment" "example" {
  role       = aws_iam_role.example.name
  policy_arn = aws_iam_policy.example.arn
}
```

For Lambda in VPC, attach the managed policy:

```hcl
resource "aws_iam_role_policy_attachment" "vpc" {
  role       = aws_iam_role.example.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
```

---

## Lambda Patterns

Terraform creates a stub. CI/CD deploys real code. Use `lifecycle.ignore_changes` to prevent conflicts.

```hcl
data "archive_file" "stub" {
  type        = "zip"
  output_path = "${path.module}/.terraform/tmp/${local.module_name}-stub.zip"
  source {
    content  = "exports.handler = async () => ({ statusCode: 200 });"
    filename = "index.js"
  }
}

resource "aws_lambda_function" "example" {
  filename         = data.archive_file.stub.output_path
  function_name    = "${var.resource_prefix}_${local.module_name}_example"
  role             = aws_iam_role.example.arn
  handler          = "index.handler"
  runtime          = "nodejs24.x"
  timeout          = 30
  source_code_hash = data.archive_file.stub.output_base64sha256

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.lambdas.id]
  }

  environment {
    variables = merge(var.environment_variables, {
      PARAM_ARN = aws_ssm_parameter.example.arn
    })
  }

  lifecycle {
    ignore_changes = [filename, source_code_hash, s3_key, s3_object_version]
  }
}
```

For Cognito triggers, grant invoke permission:

```hcl
resource "aws_lambda_permission" "cognito" {
  statement_id  = "AllowCognitoInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.example.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = var.user_pool_arn
}
```

---

## Security Group Pattern

```hcl
resource "aws_security_group" "example" {
  name        = "${var.resource_prefix}_example"
  description = "Security group for example component"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.allowed_sg_ids
    content {
      from_port       = 5432
      to_port         = 5432
      protocol        = "tcp"
      security_groups = [ingress.value]
      description     = "Allow inbound from allowed service"
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
    #checkov:skip=CKV_AWS_25:Unrestricted egress is intentional for this component
  }

  tags = { Name = "${var.resource_prefix}_example" }
}
```

Prefer dynamic ingress from security group IDs over CIDR ranges wherever possible.

---

## SSM Parameters for Secrets

```hcl
resource "aws_ssm_parameter" "example" {
  name        = "/${var.resource_prefix}/service/param_name"
  description = "Human-readable description"
  value       = "Dummy"
  type        = "SecureString"
  tier        = "Standard"

  lifecycle {
    ignore_changes = [value]
  }
}
```

Pass SSM parameter ARNs (not values) between modules.

---

## S3 Bucket Pattern

```hcl
resource "aws_s3_bucket" "example" {
  bucket = "${var.resource_prefix_alt}-example"
  tags   = { Name = "${var.resource_prefix_alt}-example" }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket                  = aws_s3_bucket.example.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

---

## ACM / TLS

- Never use wildcard certificates — issue individual certificates per subdomain.
- Use `aws_acm_certificate_validation` to block until DNS validation completes before attaching to a listener or CloudFront distribution.
- Always set `create_before_destroy = true` on certificate replacements to avoid downtime.

---

## Conditional Resources

Use `for_each` with a conditional map instead of `count` for optional resources:

```hcl
resource "aws_wafv2_web_acl" "cf" {
  for_each = var.waf_enable ? { "main" = true } : {}
}
```

---

## Data Source Conventions

```hcl
data "aws_caller_identity" "current" {}
data "aws_region" "current"          {}
data "aws_availability_zones" "available" { state = "available" }

data "aws_security_group" "allowed" {
  for_each = toset(var.allowed_sg_ids)
  id       = each.value
}
```

---

## Checkov

Run checkov on every file and directory before committing. Address every finding:

- **Fix it** — preferred; resolve the misconfiguration directly.
- **Skip with justification** — acceptable when the check does not apply; document why inline.

```hcl
resource "aws_s3_bucket" "logs" {
  #checkov:skip=CKV_AWS_144:Logs-only bucket, cross-region replication not required
  bucket = "${var.resource_prefix_alt}-logs"
}
```

Common checks to be aware of:

| Check ID         | What it enforces                                      |
|------------------|-------------------------------------------------------|
| CKV_AWS_18       | S3 access logging enabled                             |
| CKV_AWS_52       | S3 MFA delete                                         |
| CKV_AWS_144      | S3 cross-region replication                           |
| CKV_AWS_116      | Lambda dead-letter queue configured                   |
| CKV_AWS_50       | Lambda X-Ray tracing enabled                          |
| CKV_AWS_272      | Lambda code signing                                   |
| CKV_AWS_19       | RDS storage encryption                                |
| CKV_AWS_16       | RDS deletion protection                               |
| CKV_AWS_2        | ALB HTTPS listeners only                              |
| CKV_AWS_91       | ALB access logging enabled                            |
| CKV_AWS_7        | KMS key rotation enabled                              |

Never suppress a checkov finding without a one-line explanation on the same `#checkov:skip` comment.

---

## RDS / Database

- `storage_encrypted = true`
- `deletion_protection = true`
- `skip_final_snapshot = false`
- Place in private subnets with a dedicated subnet group.
- Restrict ingress to specific security groups (API, bastion), never open CIDR.

---

## Security Baselines

Enable in every environment:

| Control             | Resource                                        |
|---------------------|-------------------------------------------------|
| VPC Flow Logs       | CloudWatch, 14-day retention                    |
| CloudTrail          | Multi-region, log validation, CloudWatch export |
| GuardDuty           | Findings routed to SNS + email                  |
| WAF                 | CloudFront, rate-limit 10k req/s per IP         |
| CloudWatch alarms   | EC2 changes, RDS changes, auth failures         |
