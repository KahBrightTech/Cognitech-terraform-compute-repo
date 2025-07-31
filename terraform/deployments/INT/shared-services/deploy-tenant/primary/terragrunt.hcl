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
  deployment         = "tenants-resources"
  region_context     = "primary"
  deploy_globally    = "true"
  region             = local.region_context == "primary" ? include.cloud.locals.regions.use1.name : include.cloud.locals.regions.usw2.name
  region_prefix      = local.region_context == "primary" ? include.cloud.locals.region_prefix.primary : include.cloud.locals.region_prefix.secondary
  region_blk         = local.region_context == "primary" ? include.cloud.locals.regions.use1 : include.cloud.locals.regions.usw2
  account_details    = include.cloud.locals.account_info[include.env.locals.name_abr]
  account_name       = local.account_details.name
  deployment_name    = "terraform/${include.env.locals.name_abr}-${local.vpc_name}-${local.deployment}"
  state_bucket       = local.region_context == "primary" ? "${local.account_name}-${include.cloud.locals.region_prefix.primary}-${local.vpc_name}-config-bucket" : "${local.account_name}-${include.cloud.locals.region_prefix.secondary}-${local.vpc_name}-config-bucket"
  vpc_name           = "shared-services"
  vpc_name_abr       = "shared"
  account_id         = include.cloud.locals.account_info[include.env.locals.name_abr].number
  aws_account_name   = include.cloud.locals.account_info[include.env.locals.name_abr].name
  public_hosted_zone = "${local.vpc_name_abr}.${include.env.locals.public_domain}"

  # Composite variables 
  tags = merge(
    include.env.locals.tags,
    {
      Environment = "shr"
      ManagedBy   = "terraform:${local.deployment_name}"
    }
  )
}

#-------------------------------------------------------
# Dependencies 
#-------------------------------------------------------
dependency "shared_services" {
  config_path = "../../acquire-state/${local.region_context}"
}
#-------------------------------------------------------
# Source
#-------------------------------------------------------
terraform {
  source = "../../../../..//formations/Create-Tenant-resources"
}
#-------------------------------------------------------
# Inputs 
#-------------------------------------------------------
inputs = {
  common = {
    global           = local.deploy_globally
    account_name     = include.cloud.locals.account_info[include.env.locals.name_abr].name
    region_prefix    = local.region_prefix
    tags             = local.tags
    region           = local.region
    account_name_abr = include.env.locals.name_abr
  }
  ec2_instances = [
    {
      index         = "ans"
      name          = "ansible-server"
      attach_tg     = ["acct-tg"]
      name_override = "INTPP-SHR-L-ANSIBLE-01"
      ami_config = {
        os_release_date = "AL2023"
      }
      associate_public_ip_address = true
      instance_type               = "t3.medium"
      iam_instance_profile        = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.ec2_profiles[local.vpc_name].iam_profiles.name
      os_release_date             = "RHEL9"
      associate_public_ip_address = true
      instance_type               = "t3.medium"
      key_name                    = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.ec2_key_pairs["${local.vpc_name}-key-pair"].name
      custom_tags = {
        "Name"       = "INTPP-SHR-L-ANSIBLE-01"
        "DNS_Suffix" = "shr.cognitech.com"
      }
      ebs_device_volume = {
        name                  = "xvdb"
        volume_size           = 30
        volume_type           = "gp3"
        delete_on_termination = true
        encrypted             = false
      }
      subnet_id     = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].public_subnet[include.env.locals.subnet_prefix.primary].primary_subnet_id
      Schedule_name = "ansible-server-schedule"
      security_group_ids = [
        dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].security_group.app.id
      ]
      hosted_zones = {
        name    = "ans01.${dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].zones[local.vpc_name_abr].zone_name}"
        zone_id = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].zones[local.vpc_name_abr].zone_id
        type    = "A"
      }
    }
  ]
  alb_listeners = [
    {
      key             = "etl"
      alb_arn         = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.load_balancers["etl"].arn
      certificate_arn = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.certificates[local.vpc_name].arn
      protocol        = "HTTPS"
      port            = 443
      # vpc_name_abr    = local.vpc_name_abr
      vpc_id = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].vpc_id
      target_group = {
        tg_key   = "etl-tg"
        protocol = "HTTPS"
        port     = 443
      }
    }
  ]
  alb_listener_rules = [
    {
      index_key    = "acct"
      listener_arn = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.load_balancers["acct"].default_listener.arn
      rules = [
        {
          key      = "acct"
          priority = 10
          type     = "forward"
          target_groups = [
            {
              tg_name = "acct-tg"
              weight  = 99
            }
          ]
          conditions = [
            {
              host_headers = [
                "acct.${local.public_hosted_zone}",
              ]
            }
          ]
        }
      ]
    }
  ]
  nlb_listeners = [
    {
      key             = "ssrs"
      nlb_key         = "ssrs-nlb"
      nlb_arn         = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.load_balancers["ssrs"].arn
      certificate_arn = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.certificates[local.vpc_name].arn
      protocol        = "TLS"
      port            = 443
      # vpc_name_abr    = local.vpc_name_abr
      vpc_id = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].vpc_id
      target_group = {
        name = "ssrs-tg"
        attachments = [
          {
            ec2_key = "ans"
            port    = 443
          }
        ]
        health_check = {
          protocol = "HTTPS"
          port     = 443
          path     = "/"
          matcher  = "200,401"
        }
      }
    }
  ]
  target_groups = [
    {
      key          = "acct-tg"
      name         = "acct-tg"
      protocol     = "HTTPS"
      port         = 443
      vpc_name_abr = "${local.vpc_name_abr}"
      health_check = {
        protocol = "HTTPS"
        port     = "443"
        path     = "/"
      }
      vpc_id = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].vpc_id
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



