#-------------------------------------------------------
# Includes Block 
#-------------------------------------------------------

include "cloud" {
  path   = find_in_parent_folders("locals-cloud.hcl")
  expose = true
}

include "env" {
  path   = find_in_parent_folders("locals-env.hcl")
  expose = true
}
#-------------------------------------------------------
# Locals 
#-------------------------------------------------------
locals {

  deployment       = "acquire-tfstate"
  region_context   = "primary"
  region           = local.region_context == "primary" ? include.cloud.locals.regions.use1.name : include.cloud.locals.regions.usw2.name
  region_prefix    = local.region_context == "primary" ? include.cloud.locals.region_prefix.primary : include.cloud.locals.region_prefix.secondary
  region_blk       = local.region_context == "primary" ? include.cloud.locals.regions.use1 : include.cloud.locals.regions.usw2
  account_details  = include.cloud.locals.account_info[include.env.locals.name_abr]
  account_name     = local.account_details.name
  deployment_name  = "terraform/${include.env.locals.repo_name}-${local.aws_account_name}-${local.vpc_name_abr}-${local.deployment}-${local.region_context}"
  state_bucket     = local.region_context == "primary" ? "${local.account_name}-${include.cloud.locals.region_prefix.primary}-${local.shared_vpc_name}-config-bucket" : "${local.account_name}-${include.cloud.locals.region_prefix.secondary}-${local.vpc_name}-config-bucket"
  account_id       = include.cloud.locals.account_info[include.env.locals.name_abr].number
  aws_account_name = include.cloud.locals.account_info[include.env.locals.name_abr].name
  ## Updates these variables as per the product/service
  shared_vpc_name = "shared-services"
  vpc_name        = "development"
  vpc_name_abr    = "dev"
  # Composite variables 
  tags = merge(
    include.env.locals.tags,
    {
      Environment = "dev"
      ManagedBy   = "${local.deployment_name}"
    }
  )
}

#-------------------------------------------------------
# Source  
#-------------------------------------------------------
terraform {
  source = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/acquire-state?ref=v1.1.55"
}
#-------------------------------------------------------
# Inputs 
#-------------------------------------------------------
inputs = {
  tf_remote_states = [
    {
      name            = "Shared"
      bucket_name     = include.env.locals.network_config_state.bucket_name[local.region_context]
      bucket_key      = "terraform/${include.cloud.locals.network_repo}-${local.aws_account_name}-${include.cloud.locals.network_deployment_types.shared_services}-${local.shared_vpc_name}-${local.region_context}/terraform.tfstate"
      lock_table_name = include.env.locals.network_config_state.remote_dynamodb_table
    },
    {
      name            = "Tenant"
      bucket_name     = include.env.locals.network_config_state.bucket_name[local.region_context]
      bucket_key      = "terraform/${include.cloud.locals.network_repo}-${local.aws_account_name}-${include.cloud.locals.network_deployment_types.tenant}-${local.vpc_name}-${local.region_context}/terraform.tfstate"
      lock_table_name = include.env.locals.network_config_state.remote_dynamodb_table
    }
  ]
}

#-------------------------------------------------------
# State Configuration
#-------------------------------------------------------
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    bucket               = local.state_bucket
    bucket_sse_algorithm = "AES256"
    dynamodb_table       = include.env.locals.remote_state_bucket.remote_dynamodb_table
    encrypt              = true
    key                  = "${local.deployment_name}/terraform.tfstate"
    region               = local.region
  }
}
#-------------------------------------------------------
# Providers 
#-------------------------------------------------------
generate "aws-providers" {
  path      = "aws-provider.tf"
  if_exists = "overwrite"
  contents  = <<-EOF
  provider "aws" {
    region = "${local.region}"
  }
  EOF
}




