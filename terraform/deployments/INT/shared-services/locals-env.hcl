locals {
  cloud = read_terragrunt_config(find_in_parent_folders("locals-cloud.hcl"))

  # Simple variables 
  name_abr = "intpp"

  # Environment tags 
  build       = "terraform"
  compliance  = "hippaa"
  environment = "uat"
  owner       = "kbrigthain@gmail.com"

  remote_state_bucket = {
    remote_dynamodb_table = "Terragrunt"
  }
  resource_prefix = "cognitech-${local.name_abr}"

  network_config_state = {
    bucket_name = {
      primary   = "terragruntint"
      secondary = "terragruntintusw2"
    }
    key_shared_services      = "${local.name_abr}-shared-services"
    remote_dynamodb_table    = "Terragrunt"
    shared_services_vpc_name = "shared-services"
  }

  tags = {
    Environment  = local.environment
    Owner        = local.owner
    Build-method = local.build
    Compliance   = local.compliance
  }
}
