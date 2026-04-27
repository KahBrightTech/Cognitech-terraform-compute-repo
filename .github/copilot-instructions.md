# Copilot Instructions for Cognitech Terraform Compute Repo

## Variables — CHANGE THESE PER DEPLOYMENT

Update the values below before each deployment. The rest of this file
references these variables. When you move to a new account, only this
section needs to change.

```
FEATURE_BRANCH_NAME:    building-intp-resources
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
1. The GitHub Actions workflow (`WORKFLOW_FILE`) **runs automatically** when you push commits to the feature branch.
2. **Plan runs WITHOUT approval** - it executes immediately on push.
3. Plan output is posted as a comment on the PR for review.
4. GitHub notifies the user of the workflow result (success/failure).
5. The user reviews the plan output on the PR and merges to `main`.
6. A fresh `terragrunt plan` **runs automatically on main** (no approval required for plan).
7. When ready to apply changes, the user **manually triggers the workflow** from GitHub Actions UI:
   - Go to Actions → Select the workflow → Click "Run workflow"
   - Select branch: `main`
   - Select action: `apply`
   - Click "Run workflow"
8. The workflow pauses at the `ENVIRONMENT_GATE` approval step before apply.
9. After user approval in GitHub UI, `terragrunt apply` runs automatically.
10. GitHub notifies the user of the apply result.

**Critical Points:**
- ✅ **Plans run automatically on push** - NO manual triggering needed, NO approval required
- ✅ **Apply requires manual trigger** - Use "Run workflow" button in GitHub Actions UI
- ✅ **Approval gate only for Apply** - Plan jobs never require approval
- ❌ **Do NOT manually trigger workflows for plan** - They run automatically on push
- ❌ **Do NOT run `terragrunt plan` or `terragrunt apply` in terminal** - GitHub Actions handles this

Do NOT run `terragrunt plan` or `terragrunt apply` yourself in the terminal.

---

## Post-Deployment Configuration Variables

**Use these variables when running SSM commands or creating SSM automation workflows.** Update per environment:

```
CONFIG_WORKFLOW_NAME:     Configure-int-production-shared-servers
CONFIG_WORKFLOW_FILE:     .github/workflows/configure-servers-int-production-shared.yaml
INSTANCE_TAG_PATTERN:     INTP-SHARED-*
SSM_DOCUMENT_NAME:        <YOUR-SSM-DOCUMENT-NAME>
HEALTH_CHECK_COMMANDS:    systemctl status; df -h; free -m
CONFIG_COMMANDS:          cd /opt/app && docker-compose pull && docker-compose up -d
WAIT_FOR_INSTANCES:       300
TRIGGER_MODE:             manual
```

> **SSM_DOCUMENT_NAME**: Set this to your EXISTING SSM document name (e.g., `MyApp-DeploymentDocument`, `Configure-WebServers`). Use `AWS-RunShellScript` for ad-hoc Linux commands or `AWS-RunPowerShellScript` for Windows.

### Variable Definitions:

- **CONFIG_WORKFLOW_NAME**: Name of the configuration workflow
  - Pattern: `Configure-ACCOUNT_NAME-VPC_NAME_ABR-servers`
  
- **CONFIG_WORKFLOW_FILE**: Path to the configuration workflow file
  - Pattern: `.github/workflows/configure-servers-ACCOUNT_NAME-VPC_NAME_ABR.yaml`
  
- **INSTANCE_TAG_PATTERN**: EC2 tag pattern to match target instances
  - Pattern: `ACCOUNT_ABR-VPC_NAME_ABR-*` (e.g., `INTP-SHARED-*`, `INTPP-SHARED-L-NFS-*`)
  - Use wildcards to match multiple instances or exact names for single instances
  
- **SSM_DOCUMENT_NAME**: AWS Systems Manager document to execute
  - `AWS-RunShellScript` for Linux
  - `AWS-RunPowerShellScript` for Windows
  
- **HEALTH_CHECK_COMMANDS**: Commands to verify instance health (separated by semicolons)
  
- **CONFIG_COMMANDS**: Commands to configure/deploy applications (separated by semicolons)
  
- **WAIT_FOR_INSTANCES**: Seconds to wait for instances to be ready (default: 300)
  
- **TRIGGER_MODE**: How the workflow starts
  - `manual` - workflow_dispatch only (recommended)
  - `automatic` - runs after successful apply via workflow_run
  - `both` - supports both manual and automatic triggers

### Quick-reference for other accounts:

**int-preproduction:**
```
CONFIG_WORKFLOW_NAME:     Configure-int-preproduction-shared-servers
CONFIG_WORKFLOW_FILE:     .github/workflows/configure-servers-int-preproduction-shared.yaml
INSTANCE_TAG_PATTERN:     INTPP-SHARED-*
```

**md-preproduction:**
```
CONFIG_WORKFLOW_NAME:     Configure-md-preproduction-shared-servers
CONFIG_WORKFLOW_FILE:     .github/workflows/configure-servers-md-preproduction-shared.yaml
INSTANCE_TAG_PATTERN:     MDPP-SHARED-*
```

**md-production:**
```
CONFIG_WORKFLOW_NAME:     Configure-md-production-shared-servers
CONFIG_WORKFLOW_FILE:     .github/workflows/configure-servers-md-production-shared.yaml
INSTANCE_TAG_PATTERN:     MDP-SHARED-*
```

---

## How to Run SSM Document on New Servers

**When asked to run an existing SSM document on newly created servers:**

1. **Verify the current variables** from the sections above:
   - `IAM_ROLE` - from deployment variables
   - `PRIMARY_REGION` - from deployment variables
   - `ACCOUNT_ABR` and `VPC_NAME_ABR` - to construct instance tag pattern
   - `SSM_DOCUMENT_NAME` - from post-deployment configuration variables

2. **Check if instances are running:**
   ```powershell
   # Configure AWS credentials
   $env:AWS_PROFILE = "<profile-name>"
   # OR use the IAM role (requires AWS CLI configured for OIDC)
   
   # Find instances by tag pattern
   aws ec2 describe-instances `
     --filters "Name=tag:Name,Values=<ACCOUNT_ABR>-<VPC_NAME_ABR>-*" `
               "Name=instance-state-name,Values=running" `
     --region <PRIMARY_REGION> `
     --query "Reservations[*].Instances[*].[InstanceId,Tags[?Key=='Name'].Value|[0],State.Name,PrivateIpAddress]" `
     --output table
   ```

3. **Check SSM connectivity:**
   ```powershell
   # Get instance IDs
   $instanceIds = aws ec2 describe-instances `
     --filters "Name=tag:Name,Values=<ACCOUNT_ABR>-<VPC_NAME_ABR>-*" `
               "Name=instance-state-name,Values=running" `
     --region <PRIMARY_REGION> `
     --query "Reservations[*].Instances[*].InstanceId" `
     --output text
   
   # Check SSM status for each instance
   foreach ($id in $instanceIds -split '\s+') {
     aws ssm describe-instance-information `
       --filters "Key=InstanceIds,Values=$id" `
       --region <PRIMARY_REGION> `
       --query "InstanceInformationList[0].[InstanceId,PingStatus,PlatformType]" `
       --output table
   }
   ```

4. **Run the SSM document:**
   ```powershell
   # Run existing SSM document on all matching instances
   $commandId = aws ssm send-command `
     --instance-ids $instanceIds `
     --document-name "<SSM_DOCUMENT_NAME>" `
     --region <PRIMARY_REGION> `
     --comment "Executed from Copilot session after deployment" `
     --query "Command.CommandId" `
     --output text
   
   Write-Host "Command ID: $commandId"
   Write-Host "Waiting for command to complete..."
   
   # Wait for command to complete (check first instance)
   $firstInstance = ($instanceIds -split '\s+')[0]
   aws ssm wait command-executed `
     --command-id $commandId `
     --instance-id $firstInstance `
     --region <PRIMARY_REGION>
   
   # Get results for each instance
   foreach ($id in $instanceIds -split '\s+') {
     Write-Host "`n=== Results for $id ==="
     aws ssm get-command-invocation `
       --command-id $commandId `
       --instance-id $id `
       --region <PRIMARY_REGION> `
       --query '[Status,StandardOutputContent,StandardErrorContent]' `
       --output text
   }
   ```

5. **If SSM document requires parameters:**
   ```powershell
   # Run with parameters
   $commandId = aws ssm send-command `
     --instance-ids $instanceIds `
     --document-name "<SSM_DOCUMENT_NAME>" `
     --parameters '{"param1":["value1"],"param2":["value2"]}' `
     --region <PRIMARY_REGION> `
     --query "Command.CommandId" `
     --output text
   ```

**How Copilot knows what to do:**

Copilot reads this instructions file but **doesn't know your deployment state**. Your request tells Copilot what action to take:

- 🆕 **"Deploy resources to int-production"** → Copilot creates PR with terragrunt files (Part 1)
- ⚙️ **"Run SSM document on int-production servers"** → Copilot runs commands on existing instances (Part 2)

The key difference: **"Deploy" vs "Run/Configure/Check"**

**Example user requests for new chat session (Part 2 - After deployment):**
- "Check if int-production servers are running and run SSM document MyApp-Deploy on them"
- "Run the existing Configure-WebServers SSM document on INTP-SHARED-* instances"
- "Verify instances are SSM-connected and execute MyCustomDocument on all new servers"
- "I just deployed servers, run the deployment SSM document on them"

**When user starts new session, you will have access to:**
- ✅ IAM_ROLE from deployment variables
- ✅ PRIMARY_REGION from deployment variables  
- ✅ ACCOUNT_ABR and VPC_NAME_ABR to build instance tag pattern
- ✅ SSM_DOCUMENT_NAME from post-deployment variables

**Important notes:**
- Always check instance state before running commands
- Verify SSM connectivity (PingStatus = "Online") before sending commands
- Show command results for each instance
- If document requires parameters, ask user for parameter values
- Use PowerShell for Windows environments, Bash for Linux

---

## Complete Two-Session Workflow

Here's how the complete deployment + configuration process works:

### 📋 Session 1: Deploy Infrastructure

**YOU SAY:**
> "Deploy resources to int-production shared-services"

**COPILOT DOES:**
1. Reads copilot-instructions.md
2. Copies terragrunt templates
3. Creates GitHub workflow
4. Opens PR
5. **Session ends when PR is merged** ❌

**YOU DO:**
1. Review PR and merge to main
2. Manually trigger workflow (Run workflow → apply)
3. Approve in GitHub
4. Wait for terraform apply to complete ✅

---

### ⚙️ Session 2: Configure Servers (NEW CHAT)

**BEFORE STARTING:** Update `SSM_DOCUMENT_NAME` in copilot-instructions.md (line 322)

**YOU SAY (in new chat):**
> "Run SSM document MyApp-Deploy on the int-production servers"

**COPILOT DOES:**
1. **Reads copilot-instructions.md again** (automatically)
2. Knows IAM_ROLE, REGION, ACCOUNT_ABR, VPC_NAME_ABR from variables
3. Finds instances matching INTP-SHARED-*
4. Checks if they're running
5. Verifies SSM connectivity
6. Runs your SSM document
7. Shows results

---

### 🔑 Key Points:

- ✅ **Copilot ALWAYS reads copilot-instructions.md** at the start of EVERY session
- ✅ **You control what Copilot does** by how you phrase your request
- ✅ **Variables persist** in the file, sessions do not
- ❌ **Copilot doesn't remember** previous sessions
- ❌ **Copilot doesn't know** if you've deployed yet (you tell it in your request)

---

## How to Create SSM Configuration Workflow

When asked to create post-deployment automation:

1. **Copy the SSM workflow template** from `terraform/templates/workflow-configure-servers.yaml` to `CONFIG_WORKFLOW_FILE`

2. **Replace placeholders** with values from both variable sections:
   - `__CONFIG_WORKFLOW_NAME__` → value of `CONFIG_WORKFLOW_NAME`
   - `__DEPLOY_WORKFLOW_NAME__` → value from deployment variables (without `.yaml`)
   - `__INSTANCE_TAG_PATTERN__` → value of `INSTANCE_TAG_PATTERN`
   - `__IAM_ROLE__` → value of `IAM_ROLE` from deployment variables
   - `__REGION__` → value of `PRIMARY_REGION` from deployment variables
   - `__SSM_DOCUMENT_NAME__` → value of `SSM_DOCUMENT_NAME`
   - `__HEALTH_CHECK_COMMANDS__` → value of `HEALTH_CHECK_COMMANDS`
   - `__CONFIG_COMMANDS__` → value of `CONFIG_COMMANDS`
   - `__WAIT_FOR_INSTANCES__` → value of `WAIT_FOR_INSTANCES`
   - `__TRIGGER_MODE__` → determines `on:` block structure

3. **Trigger modes:**
   - **manual**: Use `workflow_dispatch` only
   - **automatic**: Use `workflow_run` that triggers on deploy workflow completion
   - **both**: Include both `workflow_run` and `workflow_dispatch`

4. **Test the workflow:**
   - For manual mode: Trigger from GitHub Actions UI after apply completes
   - For automatic mode: Workflow runs automatically after successful apply
   - For both: Can run automatically OR be manually triggered

5. **Verify SSM permissions:**
   - Ensure EC2 instances have IAM role with `AmazonSSMManagedInstanceCore` policy
   - Verify SSM agent is running on instances (pre-installed on modern AMIs)
   - Check instances appear in Systems Manager → Fleet Manager
