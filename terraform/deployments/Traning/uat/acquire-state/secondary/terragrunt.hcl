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

  deployment      = "${include.env.locals.name_abr}-acquire-tfstate"
  region_context  = "secondary"
  region          = local.region_context == "primary" ? include.cloud.locals.regions.use1.name : include.cloud.locals.regions.usw2.name
  deployment_name = "terraform/${include.env.locals.name_abr}-${local.vpc_name}-${local.deployment}"
  state_bucket    = local.region_context == "primary" ? include.env.locals.remote_state_bucket.primary : include.env.locals.remote_state_bucket.secondary
  vpc_name        = "uat"

  # Composite variables 
  tags = merge(
    include.env.locals.tags,
    {
      Environment = "Development"
      ManagedBy   = "terraform:${local.deployment_name}"
    }
  )
}
#-------------------------------------------------------
# Inputs 
#-------------------------------------------------------
inputs = {
  tf_remote_states = [
    {
      name            = "Shared"
      bucket_name     = "include.env.locals.network_config_state.bucket_name[local.region_context]"
      bucket_key      = "${include.env.locals.name_abr}-${include.env.locals.network_config_state.shared_services_vpc_name}-${local.region_context}/terraform.tfstate"
      lock_table_name = include.env.locals.network_config_state.remote_dynamodb_table
    },
    {
      name            = "Tenant"
      bucket_name     = "include.env.locals.network_config_state.bucket_name[local.region_context]"
      bucket_key      = "${include.env.locals.name_abr}-${local.vpc_name}-${local.region_context}/terraform.tfstate"
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

terraform {
  source = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/acquire-state?ref=v1.1.12"
}