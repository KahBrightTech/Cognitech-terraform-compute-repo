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
    primary               = "terragruntuse-compute-state"
    secondary             = "terragruntusw2-compute-state"
    remote_dynamodb_table = "Terraform"
  }
  resource_prefix = "cognitech-${local.name_abr}"
  network_config_state = {
    bucket_name = {
      primary   = "terragruntuse1"
      secondary = "terragruntusw2"
    }
    key_shared_services      = "${local.name_abr}-shared-services"
    remote_dynamodb_table    = "Terraform"
    shared_services_vpc_name = "shared-services"
  }

  tags = {
    Environment  = local.environment
    Owner        = local.owner
    Build-method = local.build
    Compliance   = local.compliance
  }
}
