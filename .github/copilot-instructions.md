# Copilot Instructions for Cognitech Terraform Compute Repo

## Variables
```
FEATURE_BRANCH_NAME: int-production-build
```

---

## Project Overview

This repository manages AWS compute resources (EC2 instances, ALB/NLB listeners,
target groups, launch templates, auto scaling groups, EKS node groups) using
Terragrunt. The Terraform module source is at `terraform/formations/Create-Tenant-resources`.

**Terragrunt template files already exist** in environment-specific folders under
`terraform/deployments/`. Your job is to **read and modify these EXISTING files** —
never create new terragrunt files from scratch.

---

## Repository Structure

```
terraform/
├── deployments/
│   ├── locals-cloud.hcl                              # Global: accounts, regions, lambdas
│   ├── int-preproduction/                            # Account: intpp (730335294148)
│   │   ├── shared-services/
│   │   │   ├── locals-env.hcl                        # Env config (name_abr=intpp)
│   │   │   ├── acquire-state/primary/terragrunt.hcl  # DO NOT TOUCH - reads network state
│   │   │   └── deploy-tenant/primary/terragrunt.hcl  # ✅ THIS is where you work
│   │   ├── dev/
│   │   └── sit/
│   ├── int-production/                               # Account: intp (271457809232)
│   │   ├── shared-services/
│   │   │   ├── acquire-state/primary/terragrunt.hcl  # DO NOT TOUCH
│   │   │   └── deploy-tenant/primary/terragrunt.hcl  # ✅ THIS is where you work
│   │   ├── prod/
│   │   └── uat/
│   ├── md-preproduction/                             # Account: mdpp (533267408704)
│   │   ├── shared-services/
│   │   │   ├── acquire-state/primary/terragrunt.hcl  # DO NOT TOUCH
│   │   │   └── deploy-tenant/primary/terragrunt.hcl  # ✅ THIS is where you work
│   │   ├── dev/
│   │   └── trn/
│   ├── md-production/                                # Account: mdp (388927731914)
│   │   ├── shared-services/
│   │   │   ├── acquire-state/primary/terragrunt.hcl  # DO NOT TOUCH
│   │   │   └── deploy-tenant/primary/terragrunt.hcl  # ✅ THIS is where you work
│   │   └── dev/
│   └── Traning/                                      # Training environment
│       ├── dev/
│       └── uat/
├── formations/
│   └── Create-Tenant-resources/                      # DO NOT TOUCH - Terraform module
└── Archives/                                         # DO NOT TOUCH - archived configs
```

---

## Two-Phase Deployment Pattern

Each environment has TWO terragrunt modules that run in sequence:

1. **`acquire-state/`** — Reads remote state from the network repo
   (`cognitech-terraform-network-repo`) via S3. This pulls VPC IDs, subnets,
   security groups, key pairs, IAM profiles, certificates, load balancers, EKS
   clusters, and hosted zones into a local state. **NEVER modify these files.**

2. **`deploy-tenant/`** — Uses a `dependency` block pointing to `acquire-state`
   to provision compute resources. All resource blocks in these files are
   **commented out by default**. Deploying a new resource means **uncommenting**
   the correct block.

---

## How to Work on an Issue

1. Read the issue body. It will tell you:
   - Which environment folder to work in (e.g., `int-production/shared-services`)
   - Whether to target `primary` or `secondary` region
   - Which resource blocks to uncomment or modify
   - Any input values to change

2. Create a feature branch from `main` named exactly: `int-production-build`

3. Navigate to the correct `deploy-tenant` file, for example:
   `terraform/deployments/int-preproduction/shared-services/deploy-tenant/primary/terragrunt.hcl`

4. Make the changes specified in the issue. Common tasks:
   - **Uncomment an EC2 instance block** from the `ec2_instances` list
   - **Uncomment an ALB listener** from `alb_listeners`
   - **Uncomment listener rules** from `alb_listener_rules`
   - **Uncomment target groups** from `target_groups`
   - **Uncomment NLB listeners** from `nlb_listeners`
   - **Uncomment launch templates** from `launch_templates`
   - **Uncomment ASG blocks** from `Autoscaling_groups`
   - **Uncomment EKS node groups** from `eks_nodes`
   - **Modify input values** on existing uncommented blocks

5. Run `terragrunt hclfmt` to validate formatting.

6. Open a PR from the feature branch to `main` with the title pattern:
   `infra: <description> in <environment>/shared-services`

---

## Critical Rules for Cross-Repo References

The `deploy-tenant` files use `dependency.shared_services.outputs.remote_tfstates.Shared.outputs.*`
to reference values from the network repo's state. These references are resolved at
**plan/apply time** by Terraform reading the S3 state bucket.

**NEVER replace these references with hardcoded values.** Preserve them exactly.

Common reference patterns you will see:

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
dependency.shared_services.outputs.remote_tfstates.Shared.outputs.load_balancers["app"].default_listener.arn

# Certificates
dependency.shared_services.outputs.remote_tfstates.Shared.outputs.certificates[local.vpc_name].arn

# Hosted zones
dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].zones[local.vpc_name_abr].zone_name
dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].zones[local.vpc_name_abr].zone_id

# EKS clusters
dependency.shared_services.outputs.remote_tfstates.Shared.outputs.eks_clusters[include.env.locals.eks_cluster_keys.primary_cluster].eks_cluster_id

# IAM roles
dependency.shared_services.outputs.remote_tfstates.Shared.outputs.IAM_roles.shared-ec2-nodes.iam_role_arn
```

---

## Locals You Can Use (Already Defined in Each deploy-tenant File)

These locals are already defined in each `deploy-tenant/primary/terragrunt.hcl`.
Use them in your inputs — do NOT redefine them:

```hcl
local.vpc_name           # e.g., "shared-services"
local.vpc_name_abr       # e.g., "shared"
local.aws_account_name   # e.g., "int-preproduction"
local.region_context     # "primary" or "secondary"
local.region             # e.g., "us-east-1"
local.region_prefix      # e.g., "use1"
local.account_id         # e.g., "730335294148"
local.tags               # Merged tags from env + deployment
local.Misc_tags          # Extra tags defined per deployment
local.public_hosted_zone # e.g., "shared.cognitechllc.org"
```

And from the include blocks:

```hcl
include.env.locals.subnet_prefix.primary      # "sbnt1"
include.env.locals.subnet_prefix.secondary     # "sbnt2"
include.env.locals.eks_cluster_keys.primary_cluster  # e.g., "InfoGrid"
include.cloud.locals.repo.root                 # repo root path
```

---

## EC2 Instance Block Template

When uncommenting an EC2 instance, it should follow this exact structure:

```hcl
{
  index            = "SERVER_INDEX"           # unique key, e.g., "docker", "nfs", "ans"
  name             = "SERVER_NAME"            # e.g., "docker-server", "ansible-server"
  backup_plan_name = "${local.aws_account_name}-${local.region_context}-continous-backup"
  attach_tg        = ["${local.vpc_name_abr}-XXXX-tg"]  # optional, target groups to attach
  name_override    = "INTPP-SHR-L-DOCKER-01"  # final instance name
  ami_config = {
    os_release_date  = "UBUNTU20"             # AL2023, RHEL9, UBUNTU20, W22, EKSAL2023
    os_base_packages = "BASE"                 # optional, for Windows only
  }
  associate_public_ip_address = true
  instance_type               = "t3.large"
  iam_instance_profile        = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.ec2_profiles[local.vpc_name].iam_profiles.name
  key_name                    = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.ec2_key_pairs["${local.vpc_name}-key-pair"].name
  custom_tags = merge(
    local.Misc_tags,
    {
      "Name"       = "INTPP-SHR-L-DOCKER-01"
      "DNS_Prefix" = "docker01"
    }
  )
  ebs_device_volume = []     # or list of {name, volume_size, volume_type, delete_on_termination}
  ebs_root_volume = {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }
  subnet_id     = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].public_subnet[include.env.locals.subnet_prefix.primary].primary_subnet_id
  Schedule_name = "server-schedule"
  security_group_ids = [
    dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].security_group.app.id
  ]
  hosted_zones = {
    name    = "docker01.${dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].zones[local.vpc_name_abr].zone_name}"
    zone_id = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].zones[local.vpc_name_abr].zone_id
    type    = "A"
  }
}
```

---

## Name Override Convention

Server names follow the pattern: `{ACCOUNT_ABR}-{VPC_ABR}-{OS_TYPE}-{SERVICE}-{NUMBER}`

- Account abbreviations: INTPP, INTP, MDPP, MDP
- VPC abbreviation: SHR (for shared-services)
- OS type: L (Linux), W (Windows)
- Examples: `INTPP-SHR-L-DOCKER-01`, `INTPP-SHR-W-SSRS-01`, `INTPP-SHR-L-NFS-01`

---

## DO NOT Modify

- `terraform/deployments/locals-cloud.hcl` — global cloud config
- Any `locals-env.hcl` file — environment-specific config
- Any `acquire-state/` folder — remote state acquisition
- `terraform/formations/` — the Terraform module itself
- `terraform/Archives/` — archived configs
- `.github/workflows/` — CI/CD workflow files
- `.github/CODEOWNERS`
- Root files: `.gitignore`, `README.md`, `*.md`

---

## Workflow

After you open a PR:
1. The existing GitHub Actions workflow runs `terragrunt plan` automatically.
2. GitHub sends the user a notification with the workflow result (success/failure).
3. The user reviews the PR and the plan output.
4. The user merges the PR to `main`.
5. The user manually triggers the apply via `workflow_dispatch` in GitHub Actions.

Do NOT run `terragrunt plan` or `terragrunt apply` yourself.
