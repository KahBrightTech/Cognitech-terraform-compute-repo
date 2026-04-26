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
1. The GitHub Actions workflow (`WORKFLOW_FILE`) runs `terragrunt plan` on the feature branch.
2. Plan output is posted as a comment on the PR for review.
3. GitHub notifies the user of the workflow result (success/failure).
4. The user reviews the plan output on the PR and merges to `main`.
5. A fresh `terragrunt plan` runs on main and pauses for approval (`ENVIRONMENT_GATE`).
6. After approval, `terragrunt apply` runs automatically.
7. GitHub notifies the user of the apply result.

Do NOT run `terragrunt plan` or `terragrunt apply` yourself.
                                                               