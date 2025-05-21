locals {
  cloud = read_terragrunt_config(find_in_parent_folders("locals-cloud.hcl"))

  # Simple variables 
  name_abr = "tpp"

  # Environment tags 
  build       = "terraform"
  compliance  = "hippaa"
  environment = "uat"
  owner       = "kbrigthain@gmail.com"

  remote_state_bucket = {
    primary   = "terragruntuse1"
    secondary = "terragruntusw2"
  }
  remote_dynamodb_table = "Terraform"
  resource_prefix       = "cognitech-${local.name_abr}"
  config_state = {
    common_key          = "terraform/${local.name_abr}-${local.environment}-deploy-common/terraform.tfstate"
    lock_table_name     = "Terraform"
    key_shared_services = "terraform/${local.name_abr}-${local.environment}-shared-services/terraform.tfstate"
    key_tenant          = "terraform/${local.name_abr}-${local.environment}-tenant/terraform.tfstate"

  }

  tags = {
    Environment  = local.environment
    Owner        = local.owner
    Build-method = local.build
    Compliance   = local.compliance
  }
}
