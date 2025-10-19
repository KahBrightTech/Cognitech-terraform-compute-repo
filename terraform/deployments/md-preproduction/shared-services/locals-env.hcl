locals {
  cloud = read_terragrunt_config(find_in_parent_folders("locals-cloud.hcl"))

  # Simple variables 
  name_abr     = "mdpp"
  # Environment tags 
  build       = "terraform"
  compliance  = "hippaa"
  environment = "uat"
  owner       = "kbrigthain@gmail.com"

  remote_state_bucket = {
    remote_dynamodb_table = "terragrunt-lock-table"
  }
  resource_prefix = "cognitech-${local.name_abr}"
  # public_domain   = "cognitechllc.org"
  network_config_state = {
    bucket_name = {
      primary   = "md-preprod-us-east-1-network-config-state"
      secondary = "md-preprod-us-west-2-network-config-state"
    }
    key_shared_services      = "${local.name_abr}-shared-services"
    remote_dynamodb_table    = "terragrunt-lock-table"
    shared_services_vpc_name = "shared-services"
  }
  subnet_prefix = {
    primary    = "sbnt1"
    secondary  = "sbnt2"
    tertiary   = "sbnt3"
    quaternary = "sbnt4"
  }

  tags = {
    Environment  = local.environment
    Owner        = local.owner
    Build-method = local.build
    Compliance   = local.compliance
  }
}
