#-------------------------------------------------------
# Deployment Configuration — Centralized Variables
#-------------------------------------------------------
# This file provides a single place to define all account-
# specific values needed when onboarding a new account to
# the Copilot agent + Terragrunt workflow.
#
# Usage:
#   1. Copy a section below and fill in the values for your
#      new account.
#   2. Update the GitHub Actions workflow YAML (env block)
#      with the matching IAM_ROLE and DEPLOYMENT_PATH.
#   3. Update .github/copilot-instructions.md with a new
#      account section referencing these values.
#-------------------------------------------------------

#-------------------------------------------------------
# Account: int-preproduction (intpp)
#-------------------------------------------------------
# ACCOUNT_ID           = "730335294148"
# ACCOUNT_NAME         = "int-preproduction"
# ACCOUNT_ABR          = "intpp"
# NAME_ABR             = "intpp"
# IAM_ROLE             = "arn:aws:iam::730335294148:role/int-OIDCGitHubRole-role"
# PRIMARY_REGION       = "us-east-1"
# SECONDARY_REGION     = "us-west-2"
# VPC_NAME             = "shared-services"
# VPC_NAME_ABR         = "shared"
# DEPLOYMENT_PATH_PRI  = "terraform/deployments/int-preproduction/shared-services/deploy-tenant/primary"
# DEPLOYMENT_PATH_SEC  = "terraform/deployments/int-preproduction/shared-services/deploy-tenant/secondary"
# TEMPLATE_SOURCE      = "terraform/templates/preprod/terragrunt.hcl"
# WORKFLOW_FILE        = ".github/workflows/deploy-primary-int-preproduction-deploy-tenants-shared.yaml"
# ENVIRONMENT_GATE     = "production"
# TERRAFORM_VERSION    = "1.11.1"
# TERRAGRUNT_VERSION   = "v0.75.0"
# FEATURE_BRANCH_NAME  = "int-preproduction-build"

#-------------------------------------------------------
# Account: int-production (intp)
#-------------------------------------------------------
# ACCOUNT_ID           = "271457809232"
# ACCOUNT_NAME         = "int-production"
# ACCOUNT_ABR          = "intp"
# NAME_ABR             = "intp"
# IAM_ROLE             = "arn:aws:iam::271457809232:role/int-prod-OIDCGitHubRole-role"
# PRIMARY_REGION       = "us-east-1"
# SECONDARY_REGION     = "us-west-2"
# VPC_NAME             = "shared-services"
# VPC_NAME_ABR         = "shared"
# DEPLOYMENT_PATH_PRI  = "terraform/deployments/int-production/shared-services/deploy-tenant/primary"
# DEPLOYMENT_PATH_SEC  = "terraform/deployments/int-production/shared-services/deploy-tenant/secondary"
# TEMPLATE_SOURCE      = "terraform/templates/preprod/terragrunt.hcl"
# WORKFLOW_FILE        = ".github/workflows/deploy-primary-int-production-deploy-tenants-shared.yaml"
# ENVIRONMENT_GATE     = "production"
# TERRAFORM_VERSION    = "1.11.1"
# TERRAGRUNT_VERSION   = "v0.75.0"
# FEATURE_BRANCH_NAME  = "int-production-build"

#-------------------------------------------------------
# Account: md-preproduction (mdpp)
#-------------------------------------------------------
# ACCOUNT_ID           = "533267408704"
# ACCOUNT_NAME         = "md-preproduction"
# ACCOUNT_ABR          = "mdpp"
# NAME_ABR             = "mdpp"
# IAM_ROLE             = "arn:aws:iam::533267408704:role/<YOUR-OIDC-ROLE>"
# PRIMARY_REGION       = "us-east-1"
# SECONDARY_REGION     = "us-west-2"
# VPC_NAME             = "shared-services"
# VPC_NAME_ABR         = "shared"
# DEPLOYMENT_PATH_PRI  = "terraform/deployments/md-preproduction/shared-services/deploy-tenant/primary"
# DEPLOYMENT_PATH_SEC  = "terraform/deployments/md-preproduction/shared-services/deploy-tenant/secondary"
# TEMPLATE_SOURCE      = "terraform/templates/preprod/terragrunt.hcl"
# WORKFLOW_FILE        = ".github/workflows/deploy-primary-md-preproduction-deploy-tenants-shared.yaml"
# ENVIRONMENT_GATE     = "production"
# TERRAFORM_VERSION    = "1.11.1"
# TERRAGRUNT_VERSION   = "v0.75.0"
# FEATURE_BRANCH_NAME  = "md-preproduction-build"

#-------------------------------------------------------
# Account: md-production (mdp)
#-------------------------------------------------------
# ACCOUNT_ID           = "388927731914"
# ACCOUNT_NAME         = "md-production"
# ACCOUNT_ABR          = "mdp"
# NAME_ABR             = "mdp"
# IAM_ROLE             = "arn:aws:iam::388927731914:role/<YOUR-OIDC-ROLE>"
# PRIMARY_REGION       = "us-east-1"
# SECONDARY_REGION     = "us-west-2"
# VPC_NAME             = "shared-services"
# VPC_NAME_ABR         = "shared"
# DEPLOYMENT_PATH_PRI  = "terraform/deployments/md-production/shared-services/deploy-tenant/primary"
# DEPLOYMENT_PATH_SEC  = "terraform/deployments/md-production/shared-services/deploy-tenant/secondary"
# TEMPLATE_SOURCE      = "terraform/templates/prod/terragrunt.hcl"
# WORKFLOW_FILE        = ".github/workflows/deploy-primary-md-production-deploy-tenants-shared.yaml"
# ENVIRONMENT_GATE     = "production"
# TERRAFORM_VERSION    = "1.11.1"
# TERRAGRUNT_VERSION   = "v0.75.0"
# FEATURE_BRANCH_NAME  = "md-production-build"

#-------------------------------------------------------
# Template: Adding a New Account
#-------------------------------------------------------
# To onboard a new account, copy the block below and fill
# in the values. Then:
#   1. Create the folder structure:
#      terraform/deployments/<ACCOUNT_NAME>/shared-services/
#        ├── acquire-state/primary/terragrunt.hcl
#        ├── acquire-state/secondary/terragrunt.hcl
#        ├── deploy-tenant/primary/terragrunt.hcl
#        ├── deploy-tenant/secondary/terragrunt.hcl
#        └── locals-env.hcl
#   2. Copy the template HCL to both deploy-tenant paths.
#      Set region_context = "primary" in primary/ and
#      region_context = "secondary" in secondary/.
#   3. Create a GitHub Actions workflow YAML using the
#      existing workflows as a reference. Update env:
#        IAM_ROLE:         <IAM_ROLE from below>
#        REGION:           <PRIMARY_REGION>
#        DEPLOYMENT_PATH:  <DEPLOYMENT_PATH_PRI>
#   4. Add a section to .github/copilot-instructions.md.
#   5. Add the account to locals-cloud.hcl if not already
#      present.
#
# ACCOUNT_ID           = ""
# ACCOUNT_NAME         = ""
# ACCOUNT_ABR          = ""
# NAME_ABR             = ""
# IAM_ROLE             = ""
# PRIMARY_REGION       = "us-east-1"
# SECONDARY_REGION     = "us-west-2"
# VPC_NAME             = "shared-services"
# VPC_NAME_ABR         = "shared"
# DEPLOYMENT_PATH_PRI  = "terraform/deployments/<ACCOUNT_NAME>/shared-services/deploy-tenant/primary"
# DEPLOYMENT_PATH_SEC  = "terraform/deployments/<ACCOUNT_NAME>/shared-services/deploy-tenant/secondary"
# TEMPLATE_SOURCE      = "terraform/templates/preprod/terragrunt.hcl"
# WORKFLOW_FILE        = ".github/workflows/deploy-primary-<ACCOUNT_NAME>-deploy-tenants-shared.yaml"
# ENVIRONMENT_GATE     = "production"
# TERRAFORM_VERSION    = "1.11.1"
# TERRAGRUNT_VERSION   = "v0.75.0"
# FEATURE_BRANCH_NAME  = "<ACCOUNT_NAME>-build"
