# Copilot Instructions for Cognitech Terraform Compute Repo

## Variables — CHANGE THESE PER DEPLOYMENT

Update the values below before each deployment. The rest of this file
references these variables. When you move to a new account, only this
section needs to change.

```
FEATURE_BRANCH_NAME:    int-production-build
ACCOUNT_NAME:           int-production
ACCOUNT_ABR:            intp
ACCOUNT_ID:             271457809232
IAM_ROLE:               arn:aws:iam::271457809232:role/int-prod-OIDCGitHubRole-role
PRIMARY_REGION:         us-east-1
SECONDARY_REGION:       us-west-2
VPC_NAME:               shared-services
VPC_NAME_ABR:           shared
TEMPLATE_SOURCE:        terraform/templates/preprod/terragrunt.hcl
DEPLOY_PATH_PRIMARY:    terraform/deployments/int-production/shared-services/deploy-tenant/primary
DEPLOY_PATH_SECONDARY:  terraform/deployments/int-production/shared-services/deploy-tenant/secondary
WORKFLOW_FILE:          .github/workflows/deploy-primary-int-production-deploy-tenants-shared.yaml
WORKFLOW_FILE_SECONDARY: (none)
ENVIRONMENT_GATE:       production
```

> **WORKFLOW_FILE_SECONDARY** is optional. Set it to a filename like
> `.github/workflows/deploy-secondary-ACCOUNT_NAME-deploy-tenants-VPC_NAME_ABR.yaml`
> when you want Copilot to also create a workflow for the secondary region.
> Leave it as `(none)` to skip secondary workflow creation.

### Quick-reference: values for other accounts

**int-preproduction:**
```
FEATURE_BRANCH_NAME:    int-preproduction-build
ACCOUNT_NAME:           int-preproduction
ACCOUNT_ABR:            intpp
ACCOUNT_ID:             730335294148
IAM_ROLE:               arn:aws:iam::730335294148:role/int-OIDCGitHubRole-role
TEMPLATE_SOURCE:        terraform/templates/preprod/terragrunt.hcl
DEPLOY_PATH_PRIMARY:    terraform/deployments/int-preproduction/shared-services/deploy-tenant/primary
DEPLOY_PATH_SECONDARY:  terraform/deployments/int-preproduction/shared-services/deploy-tenant/secondary
WORKFLOW_FILE:          .github/workflows/deploy-primary-int-preproduction-deploy-tenants-shared.yaml
```

**md-preproduction:**
```
FEATURE_BRANCH_NAME:    md-preproduction-build
ACCOUNT_NAME:           md-preproduction
ACCOUNT_ABR:            mdpp
ACCOUNT_ID:             533267408704
IAM_ROLE:               arn:aws:iam::533267408704:role/<YOUR-OIDC-ROLE>
TEMPLATE_SOURCE:        terraform/templates/preprod/terragrunt.hcl
DEPLOY_PATH_PRIMARY:    terraform/deployments/md-preproduction/shared-services/deploy-tenant/primary
DEPLOY_PATH_SECONDARY:  terraform/deployments/md-preproduction/shared-services/deploy-tenant/secondary
WORKFLOW_FILE:          .github/workflows/deploy-primary-md-preproduction-deploy-tenants-shared.yaml
```

**md-production:**
```
FEATURE_BRANCH_NAME:    md-production-build
ACCOUNT_NAME:           md-production
ACCOUNT_ABR:            mdp
ACCOUNT_ID:             388927731914
IAM_ROLE:               arn:aws:iam::388927731914:role/<YOUR-OIDC-ROLE>
TEMPLATE_SOURCE:        terraform/templates/prod/terragrunt.hcl
DEPLOY_PATH_PRIMARY:    terraform/deployments/md-production/shared-services/deploy-tenant/primary
DEPLOY_PATH_SECONDARY:  terraform/deployments/md-production/shared-services/deploy-tenant/secondary
WORKFLOW_FILE:          .github/workflows/deploy-primary-md-production-deploy-tenants-shared.yaml
```

---

## Project Overview

This repository manages AWS compute resources (EC2 instances, ALB/NLB listeners,
target groups, launch templates, auto scaling groups, EKS node groups) using
Terragrunt. The Terraform module source is at `terraform/formations/Create-Tenant-resources`.

**Template files exist** in `terraform/templates/` (preprod/prod HCL variants and a
workflow YAML template). Your job is to:
1. **Copy** the HCL template from `TEMPLATE_SOURCE` to the `DEPLOY_PATH_PRIMARY` and `DEPLOY_PATH_SECONDARY`
2. **Set `region_context`** to `"primary"` in the primary file and `"secondary"` in the secondary file
3. **Format** the file with `terragrunt hclfmt`
4. **Copy** the workflow template from `terraform/templates/workflow-deploy-tenant.yaml` to `WORKFLOW_FILE` and replace all `__PLACEHOLDER__` values with the matching variables above
5. **Create a feature branch** named `FEATURE_BRANCH_NAME`, commit, and **open a PR**
6. **Do NOT modify the template content** beyond setting `region_context` and replacing workflow placeholders

---

## Repository Structure

```
terraform/
├── templates/
│   ├── preprod/terragrunt.hcl                         # Template for preproduction accounts
│   ├── prod/terragrunt.hcl                            # Template for production accounts
│   └── workflow-deploy-tenant.yaml                    # Template for GitHub Actions workflow
├── deployments/
│   ├── locals-cloud.hcl                               # Global: accounts, regions, lambdas
│   ├── int-preproduction/                             # Account: intpp (730335294148)
│   │   └── shared-services/
│   │       ├── locals-env.hcl                         # Env config (name_abr=intpp)
│   │       ├── acquire-state/primary/terragrunt.hcl   # DO NOT TOUCH
│   │       ├── acquire-state/secondary/terragrunt.hcl # DO NOT TOUCH
│   │       ├── deploy-tenant/primary/terragrunt.hcl   # Deploy target (primary region)
│   │       └── deploy-tenant/secondary/terragrunt.hcl # Deploy target (secondary region)
│   ├── int-production/                                # Account: intp (271457809232)
│   │   └── shared-services/
│   │       ├── locals-env.hcl                         # Env config (name_abr=intp)
│   │       ├── acquire-state/primary/terragrunt.hcl   # DO NOT TOUCH
│   │       ├── acquire-state/secondary/terragrunt.hcl # DO NOT TOUCH
│   │       ├── deploy-tenant/primary/terragrunt.hcl   # Deploy target (primary region)
│   │       └── deploy-tenant/secondary/terragrunt.hcl # Deploy target (secondary region)
│   ├── md-preproduction/                              # Account: mdpp (533267408704)
│   │   └── shared-services/
│   │       ├── locals-env.hcl                         # Env config (name_abr=mdpp)
│   │       ├── acquire-state/primary/terragrunt.hcl   # DO NOT TOUCH
│   │       ├── acquire-state/secondary/terragrunt.hcl # DO NOT TOUCH
│   │       ├── deploy-tenant/primary/terragrunt.hcl   # Deploy target (primary region)
│   │       └── deploy-tenant/secondary/terragrunt.hcl # Deploy target (secondary region)
│   ├── md-production/                                 # Account: mdp (388927731914)
│   │   └── shared-services/
│   │       ├── locals-env.hcl                         # Env config (name_abr=mdp)
│   │       ├── acquire-state/primary/terragrunt.hcl   # DO NOT TOUCH
│   │       ├── acquire-state/secondary/terragrunt.hcl # DO NOT TOUCH
│   │       ├── deploy-tenant/primary/terragrunt.hcl   # Deploy target (primary region)
│   │       └── deploy-tenant/secondary/terragrunt.hcl # Deploy target (secondary region)
│   └── Traning/
│       ├── dev/
│       └── uat/
├── formations/
│   └── Create-Tenant-resources/                       # DO NOT TOUCH - Terraform module
└── Archives/                                          # DO NOT TOUCH - archived configs
```

---

## How to Work on an Issue

1. **Read the issue body.** It will tell you which account to target.
   Cross-reference the account with the Variables section above.

2. **Create a feature branch** from `main` named exactly: `FEATURE_BRANCH_NAME`

3. **Copy the HCL template** from `TEMPLATE_SOURCE` to both:
   - `DEPLOY_PATH_PRIMARY/terragrunt.hcl`
   - `DEPLOY_PATH_SECONDARY/terragrunt.hcl`

4. **Set `region_context` correctly:**
   - In the primary file: `region_context = "primary"` (already set in template)
   - In the secondary file: change `region_context = "primary"` to `region_context = "secondary"`

5. **Do NOT modify the template content** beyond the `region_context` change.

6. **Run `terragrunt hclfmt`** to validate formatting.

7. **Create the GitHub Actions workflow** (if `WORKFLOW_FILE` does not already exist):
   - Copy `terraform/templates/workflow-deploy-tenant.yaml` to `WORKFLOW_FILE`
   - Remove the comment header block (lines starting with `#---` at the top)
   - Replace ALL `__PLACEHOLDER__` values with the actual values from the Variables section:
     - `__WORKFLOW_NAME__` → `Deploy-primary-ACCOUNT_NAME-deploy-tenants-VPC_NAME_ABR`
     - `__WORKFLOW_FILE__` → value of `WORKFLOW_FILE`
     - `__DEPLOY_PATH_PRIMARY__` → value of `DEPLOY_PATH_PRIMARY`
     - `__IAM_ROLE__` → value of `IAM_ROLE`
     - `__REGION__` → value of `PRIMARY_REGION`
     - `__ENVIRONMENT_GATE__` → value of `ENVIRONMENT_GATE`
   - This updates the workflow name, trigger paths, env block, and approval gate.
   - Do NOT modify the job structure, steps, or tool versions in the workflow.
   - Example: for int-production the workflow name becomes
     `Deploy-primary-int-production-deploy-tenants-shared` and the trigger paths
     point to `terraform/deployments/int-production/shared-services/deploy-tenant/primary/**/*`.

8. **Commit and open a PR** from `FEATURE_BRANCH_NAME` to `main` with the title:
   `infra: deploy resources to ACCOUNT_NAME/shared-services`

---

## Two-Phase Deployment Pattern

Each environment has TWO terragrunt modules that run in sequence:

1. **`acquire-state/`** — Reads remote state from the network repo
   (`cognitech-terraform-network-repo`) via S3. This pulls VPC IDs, subnets,
   security groups, key pairs, IAM profiles, certificates, load balancers, EKS
   clusters, and hosted zones into a local state. **NEVER modify these files.**

2. **`deploy-tenant/`** — Uses a `dependency` block pointing to `acquire-state`
   to provision compute resources. The template files define what resources to
   deploy. Cross-repo references resolve automatically at plan/apply time.

---

## Critical Rules

1. **Do NOT modify template content.** Copy the template file as-is. The only
   permitted change is setting `region_context` for the secondary region file.

2. **Do NOT replace cross-repo references with hardcoded values.** These resolve
   at plan/apply time from S3 remote state:
   ```hcl
   dependency.shared_services.outputs.remote_tfstates.Shared.outputs.*
   ```

3. **Do NOT modify** any of the following:
   - `terraform/deployments/locals-cloud.hcl`
   - Any `locals-env.hcl` file
   - Any `acquire-state/` folder
   - `terraform/formations/` (the Terraform module)
   - `terraform/Archives/`
   - `terraform/templates/workflow-deploy-tenant.yaml` (the workflow template)
   - **Existing** `.github/workflows/` files (do NOT edit workflows that already exist)
   - `.github/CODEOWNERS`
   - Root files: `.gitignore`, `README.md`, `deployment-config.hcl`

   **Exception:** You MAY create a NEW workflow file in `.github/workflows/` by
   copying from `terraform/templates/workflow-deploy-tenant.yaml` and replacing
   placeholders. See step 7 in "How to Work on an Issue."

4. **Do NOT run `terragrunt plan` or `terragrunt apply` yourself.** The GitHub
   Actions pipeline handles this automatically.

---

## Cross-Repo Reference Patterns (Do Not Touch)

The template files use these references (resolved from S3 at plan time):

```hcl
# IAM profiles
dependency.shared_services.outputs.remote_tfstates.Shared.outputs.ec2_profiles[local.vpc_name].iam_profiles.name

# Key pairs
dependency.shared_services.outputs.remote_tfstates.Shared.outputs.ec2_key_pairs["${local.vpc_name}-key-pair"].name

# Subnets
dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].public_subnet[include.env.locals.subnet_prefix.primary].primary_subnet_id

# Security groups
dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].security_group.app.id

# VPC IDs
dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].vpc_id

# Load balancers
dependency.shared_services.outputs.remote_tfstates.Shared.outputs.load_balancers["app"].arn

# Certificates
dependency.shared_services.outputs.remote_tfstates.Shared.outputs.certificates[local.vpc_name].arn

# Hosted zones
dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].zones[local.vpc_name_abr].zone_name

# EKS clusters
dependency.shared_services.outputs.remote_tfstates.Shared.outputs.eks_clusters[include.env.locals.eks_cluster_keys.primary_cluster].eks_cluster_id

# IAM roles
dependency.shared_services.outputs.remote_tfstates.Shared.outputs.IAM_roles.shared-ec2-nodes.iam_role_arn
```

---

## Locals (Already Defined — Do Not Redefine)

```hcl
local.vpc_name           # "shared-services"
local.vpc_name_abr       # "shared"
local.aws_account_name   # Resolved from ACCOUNT_NAME via locals-cloud.hcl
local.region_context     # "primary" or "secondary"
local.region             # Resolved from region_context
local.region_prefix      # e.g., "use1" or "usw2"
local.account_id         # Resolved from ACCOUNT_ID via locals-cloud.hcl
local.tags               # Merged tags
local.Misc_tags          # Extra tags
local.public_hosted_zone # Resolved from locals-env.hcl
```

---

## Name Override Convention

Server names use dynamic expressions for portability across accounts:
`${upper(local.aws_account_name)}-${upper(local.vpc_name_abr)}-{OS_TYPE}-{SERVICE}-{NUMBER}`

OS type: L (Linux), W (Windows)

---

## Workflow

After you open a PR:
1. The GitHub Actions workflow (`WORKFLOW_FILE`) runs `terragrunt plan` automatically on the feature branch.
2. Plan output is posted as a comment on the PR for review.
3. GitHub notifies the user of the workflow result (success/failure).
4. The user reviews the plan output on the PR and merges to `main`.
5. A fresh `terragrunt plan` runs automatically on main (no approval required for plan).
6. The workflow pauses at the `ENVIRONMENT_GATE` approval step before apply.
7. After user approval, `terragrunt apply` runs automatically.
8. GitHub notifies the user of the apply result.

**Summary:** Plans run automatically on both feature branch and main. User approval is only required before the apply step.

Do NOT run `terragrunt plan` or `terragrunt apply` yourself.

---
---

# PART 2: Updating Existing Deployments

## Update Variables — CHANGE THESE PER UPDATE

Use these variables when updating an **existing** deployment file. Set the values
based on which account/environment you're updating.

```
UPDATE_FEATURE_BRANCH:  update-int-production-resources
UPDATE_ACCOUNT_NAME:    int-production
UPDATE_ACCOUNT_ABR:     intp
UPDATE_VPC_NAME:        shared-services
UPDATE_VPC_NAME_ABR:    shared
UPDATE_FILE_PRIMARY:    terraform/deployments/int-production/shared-services/deploy-tenant/primary/terragrunt.hcl
UPDATE_FILE_SECONDARY:  terraform/deployments/int-production/shared-services/deploy-tenant/secondary/terragrunt.hcl
UPDATE_REGION_CONTEXT:  primary
CHANGE_DESCRIPTION:     Add NLB listener for new service
```

### Quick-reference: update paths for other accounts

**int-preproduction:**
```
UPDATE_FEATURE_BRANCH:  update-int-preproduction-resources
UPDATE_ACCOUNT_NAME:    int-preproduction
UPDATE_ACCOUNT_ABR:     intpp
UPDATE_FILE_PRIMARY:    terraform/deployments/int-preproduction/shared-services/deploy-tenant/primary/terragrunt.hcl
UPDATE_FILE_SECONDARY:  terraform/deployments/int-preproduction/shared-services/deploy-tenant/secondary/terragrunt.hcl
```

**md-preproduction:**
```
UPDATE_FEATURE_BRANCH:  update-md-preproduction-resources
UPDATE_ACCOUNT_NAME:    md-preproduction
UPDATE_ACCOUNT_ABR:     mdpp
UPDATE_FILE_PRIMARY:    terraform/deployments/md-preproduction/shared-services/deploy-tenant/primary/terragrunt.hcl
UPDATE_FILE_SECONDARY:  terraform/deployments/md-preproduction/shared-services/deploy-tenant/secondary/terragrunt.hcl
```

**md-production:**
```
UPDATE_FEATURE_BRANCH:  update-md-production-resources
UPDATE_ACCOUNT_NAME:    md-production
UPDATE_ACCOUNT_ABR:     mdp
UPDATE_FILE_PRIMARY:    terraform/deployments/md-production/shared-services/deploy-tenant/primary/terragrunt.hcl
UPDATE_FILE_SECONDARY:  terraform/deployments/md-production/shared-services/deploy-tenant/secondary/terragrunt.hcl
```

---

## How to Update Existing Resources

When a user asks to add/modify/remove resources in an existing deployment:

1. **Identify the target file** using `UPDATE_FILE_PRIMARY` or `UPDATE_FILE_SECONDARY`
   based on which region the user wants to update.

2. **Read the existing file** to understand the current configuration.

3. **Create a feature branch** named `UPDATE_FEATURE_BRANCH`.

4. **Make the requested changes** to the `inputs` block in the terragrunt.hcl file:
   - Add new resources to the appropriate list (ec2_instances, alb_listeners, nlb_listeners, target_groups, etc.)
   - Modify existing resource configurations
   - Remove resources by deleting their entries
   - **ALWAYS use the variable references** as shown in the template (e.g., `local.vpc_name_abr`, `${upper(local.aws_account_name)}`, etc.)
   - **NEVER hardcode values** that can be derived from variables

5. **Use proper name override patterns** for all resources:
   - EC2 instances: `${upper(local.aws_account_name)}-${upper(local.vpc_name_abr)}-{OS}-{SERVICE}-{NUMBER}`
   - Target groups: `${local.vpc_name_abr}-{service}-tg`
   - Follow the existing naming patterns in the file

6. **Maintain consistency** with existing cross-repo references:
   - Use `dependency.shared_services.outputs.remote_tfstates.Shared.outputs.*` for all shared resources
   - Do NOT hardcode ARNs, IDs, subnet IDs, security group IDs, etc.

7. **Run `terragrunt hclfmt`** to format the file.

8. **Commit and open a PR** with title:
   `infra: CHANGE_DESCRIPTION for UPDATE_ACCOUNT_NAME/UPDATE_VPC_NAME`

---

## Common Update Scenarios

### Adding an ALB Listener

Add to the `alb_listeners` list in the inputs block:

```hcl
{
  key             = "service-name"
  action          = "forward"  # or "fixed-response"
  alb_arn         = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.load_balancers["app"].arn
  certificate_arn = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.certificates[local.vpc_name].arn
  protocol        = "HTTPS"
  port            = 443
  vpc_id          = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].vpc_id
  target_group = {
    name = "${local.vpc_name_abr}-service-tg"
    # ... rest of target group config
  }
}
```

### Adding an ALB Listener Rule

Add to the `alb_listener_rules` list:

```hcl
{
  index_key    = "app"
  listener_arn = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.load_balancers["app"].default_listener.arn
  rules = [
    {
      key      = "new-service"
      priority = 20  # Must be unique
      type     = "forward"
      target_groups = [
        {
          tg_name = "${local.vpc_name_abr}-new-service-tg"
          weight  = 99
        }
      ]
      conditions = [
        {
          host_headers = [
            "service.${local.public_hosted_zone}",
          ]
        }
      ]
    }
  ]
}
```

### Adding an NLB Listener

Add to the `nlb_listeners` list:

```hcl
{
  key             = "service-name"
  nlb_key         = "nlb-name"
  nlb_arn         = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.load_balancers["nlb-name"].arn
  certificate_arn = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.certificates[local.vpc_name].arn
  protocol        = "TLS"  # or "TCP"
  port            = 443
  vpc_id          = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].vpc_id
  target_group = {
    name        = "${local.vpc_name_abr}-service-tg"
    port        = 443
    protocol    = "TLS"  # or "TCP"
    target_type = "instance"
    attachments = [
      {
        ec2_key = "service"  # Must match an ec2_instance index key
        port    = 443
      }
    ]
    health_check = {
      protocol = "HTTPS"  # or "TCP"
      port     = 443
      path     = "/"  # Only for HTTPS/HTTP
      matcher  = "200,401"  # Only for HTTPS/HTTP
    }
  }
}
```

### Adding a Target Group

Add to the `target_groups` list:

```hcl
{
  name        = "${local.vpc_name_abr}-service-tg"
  protocol    = "HTTP"  # or HTTPS, TCP, TLS
  port        = 8080
  target_type = "instance"
  health_check = {
    protocol            = "HTTP"
    port                = "8080"
    path                = "/"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200-399"
  }
  vpc_id = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].vpc_id
}
```

### Adding an EC2 Instance

Add to the `ec2_instances` list:

```hcl
{
  index            = "service"  # Unique identifier
  name             = "service-server"
  backup_plan_name = "${local.aws_account_name}-${local.region_context}-continous-backup"
  name_override    = "${upper(local.aws_account_name)}-${upper(local.vpc_name_abr)}-L-SERVICE-01"
  ami_config = {
    os_release_date  = "AL2023"  # or "W22" for Windows
    os_base_packages = "BASE"     # Optional, for Windows
  }
  associate_public_ip_address = true
  instance_type               = "t3.large"
  iam_instance_profile        = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.ec2_profiles[local.vpc_name].iam_profiles.name
  key_name                    = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.ec2_key_pairs["${local.vpc_name}-key-pair"].name
  custom_tags = merge(
    local.Misc_tags,
    {
      "Name"       = "${upper(local.aws_account_name)}-${upper(local.vpc_name_abr)}-L-SERVICE-01"
      "DNS_Prefix" = "service01"
      "CreateUser" = "True"
    }
  )
  ebs_device_volume = []  # Or add volumes
  ebs_root_volume = {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }
  subnet_id     = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].public_subnet[include.env.locals.subnet_prefix.primary].primary_subnet_id
  Schedule_name = "service-server-schedule"
  security_group_ids = [
    dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].security_group.app.id
  ]
  hosted_zones = {
    name    = "service01.${dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].zones[local.vpc_name_abr].zone_name}"
    zone_id = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].zones[local.vpc_name_abr].zone_id
    type    = "A"
  }
}
```

---

## Critical Rules for Updates

1. **Always use variable references** — Never hardcode account names, VPC names, or region-specific values:
   - ✅ `${upper(local.aws_account_name)}-${upper(local.vpc_name_abr)}-L-APP-01`
   - ❌ `INTP-SHARED-L-APP-01`

2. **Use cross-repo references** — Never hardcode resource IDs, ARNs, or subnet IDs:
   - ✅ `dependency.shared_services.outputs.remote_tfstates.Shared.outputs.load_balancers["app"].arn`
   - ❌ `arn:aws:elasticloadbalancing:us-east-1:271457809232:loadbalancer/app/...`

3. **Maintain naming consistency:**
   - Target groups: `${local.vpc_name_abr}-{service}-tg`
   - EC2 name_override: `${upper(local.aws_account_name)}-${upper(local.vpc_name_abr)}-{OS}-{SERVICE}-{NUMBER}`
   - DNS prefix: lowercase, matches service name

4. **Preserve existing structure** — Do not reformat or reorganize the file beyond the specific change requested.

5. **Update both regions if needed** — If the change applies to both primary and secondary regions,
   update both `UPDATE_FILE_PRIMARY` and `UPDATE_FILE_SECONDARY`.

6. **Reference existing EC2 instances correctly** — When attaching instances to NLB target groups,
   use the `ec2_key` that matches the `index` field of the ec2_instance.

7. **Unique priorities for ALB rules** — Each listener rule must have a unique priority number.

8. **Run `terragrunt hclfmt`** after making changes to ensure proper formatting.

---

## Update Workflow

After you open an update PR:
1. GitHub Actions runs `terragrunt plan` automatically on the feature branch.
2. The plan shows what resources will be added/changed/destroyed.
3. User reviews the plan output in the PR comments.
4. User merges the PR to `main`.
5. Plan runs again on main automatically.
6. User approves at the environment gate.
7. `terragrunt apply` runs and provisions the changes.

**The existing workflow file already handles updates** — you do NOT need to create a new workflow.
