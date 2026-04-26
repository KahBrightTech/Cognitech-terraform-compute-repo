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
  region_context     = "secondary"
  deploy_globally    = "true"
  region             = local.region_context == "primary" ? include.cloud.locals.regions.use1.name : include.cloud.locals.regions.usw2.name
  region_prefix      = local.region_context == "primary" ? include.cloud.locals.region_prefix.primary : include.cloud.locals.region_prefix.secondary
  region_blk         = local.region_context == "primary" ? include.cloud.locals.regions.use1 : include.cloud.locals.regions.usw2
  account_details    = include.cloud.locals.account_info[include.env.locals.name_abr]
  account_name       = local.account_details.name
  deployment_name    = "terraform/${include.cloud.locals.repo_name}-${local.aws_account_name}-${local.vpc_name_abr}-${local.deployment}-${local.region_context}"
  state_bucket       = local.region_context == "primary" ? "${local.account_name}-${include.cloud.locals.region_prefix.primary}-${local.vpc_name_abr}-config-bucket" : "${local.account_name}-${include.cloud.locals.region_prefix.secondary}-${local.vpc_name_abr}-config-bucket"
  account_id         = include.cloud.locals.account_info[include.env.locals.name_abr].number
  aws_account_name   = include.cloud.locals.account_info[include.env.locals.name_abr].name
  public_hosted_zone = "${local.vpc_name_abr}.${include.env.locals.public_domain}"
  deployment         = "deploy-tenant"
  ## Updates these variables as per the product/service
  vpc_name     = "shared-services"
  vpc_name_abr = "shared"
  Misc_tags = {
    "PrivateHostedZone" = "shared.cognitech.com"
    "PublicHostedZone"  = "cognitech.com"
  }

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
      index            = "nfs"
      name             = "ansible-server"
      backup_plan_name = "${local.aws_account_name}-${local.region_context}-continous-backup"
      name_override    = "INTPP-SHR-L-NFS-01"
      ami_config = {
        os_release_date = "AL2023"
      }
      associate_public_ip_address = true
      instance_type               = "t3.large"
      iam_instance_profile        = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.ec2_profiles[local.vpc_name].iam_profiles.name
      associate_public_ip_address = true
      key_name                    = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.ec2_key_pairs["${local.vpc_name}-key-pair"].name
      custom_tags = merge(
        local.Misc_tags,
        {
          "Name"       = "INTPP-SHR-L-NFS-01"
          "DNS_Prefix" = "nfs01"
          "CreateUser" = "True"
        }
      )
      ebs_device_volume = []
      ebs_root_volume = {
        volume_size           = 30
        volume_type           = "gp3"
        delete_on_termination = true
      }
      subnet_id     = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].public_subnet[include.env.locals.subnet_prefix.primary].primary_subnet_id
      Schedule_name = "nfs-server-schedule"
      security_group_ids = [
        dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].security_group.app.id
      ]
      hosted_zones = {
        name    = "nfs01.${dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].zones[local.vpc_name_abr].zone_name}"
        zone_id = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].zones[local.vpc_name_abr].zone_id
        type    = "A"
      }
    },
    {
      index            = "ssrs1"
      name             = "ssrs-server"
      backup_plan_name = "${local.aws_account_name}-${local.region_context}-continous-backup"
      name_override    = "${upper(local.aws_account_name)}-${upper(local.vpc_name_abr)}-W-SSRS-01"
      ami_config = {
        os_release_date  = "W22"
        os_base_packages = "BASE"
      }
      associate_public_ip_address = true
      instance_type               = "t3.large"
      iam_instance_profile        = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.ec2_profiles[local.vpc_name].iam_profiles.name
      associate_public_ip_address = true
      key_name                    = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.ec2_key_pairs["${local.vpc_name}-key-pair"].name
      custom_tags = merge(
        local.Misc_tags,
        {
          "Name"                = "${upper(local.aws_account_name)}-${upper(local.vpc_name_abr)}-W-SSRS-01"
          "DNS_Prefix"          = "ssrs01"
          "CreateUser"          = "True"
          "WinRMInstall"        = "True"
          "WindowsBannerConfig" = "True"
        }
      )
      ebs_device_volume = [
        {
          name                  = "xvdf"
          volume_size           = 30
          volume_type           = "gp3"
          delete_on_termination = true
        }
      ]
      ebs_root_volume = {
        volume_size           = 50
        volume_type           = "gp3"
        delete_on_termination = true
      }
      subnet_id     = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].public_subnet[include.env.locals.subnet_prefix.primary].primary_subnet_id
      Schedule_name = "ansible-server-schedule"
      security_group_ids = [
        dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].security_group.app.id
      ]
      hosted_zones = {
        name    = "ssrs01.${dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].zones[local.vpc_name_abr].zone_name}"
        zone_id = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].zones[local.vpc_name_abr].zone_id
        type    = "A"
      }
    },
    {
      index            = "ssrs2"
      name             = "ssrs-server"
      backup_plan_name = "${local.aws_account_name}-${local.region_context}-continous-backup"
      name_override    = "${upper(local.aws_account_name)}-${upper(local.vpc_name_abr)}-W-SSRS-02"
      ami_config = {
        os_release_date  = "W22"
        os_base_packages = "BASE"
      }
      associate_public_ip_address = true
      instance_type               = "t3.large"
      iam_instance_profile        = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.ec2_profiles[local.vpc_name].iam_profiles.name
      associate_public_ip_address = true
      key_name                    = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.ec2_key_pairs["${local.vpc_name}-key-pair"].name
      custom_tags = merge(
        local.Misc_tags,
        {
          "Name"                = "${upper(local.aws_account_name)}-${upper(local.vpc_name_abr)}-W-SSRS-02"
          "DNS_Prefix"          = "ssrs02"
          "CreateUser"          = "True"
          "WinRMInstall"        = "True"
          "WindowsBannerConfig" = "True"
        }
      )
      ebs_device_volume = []
      ebs_root_volume = {
        volume_size           = 50
        volume_type           = "gp3"
        delete_on_termination = true
      }
      subnet_id     = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].public_subnet[include.env.locals.subnet_prefix.primary].primary_subnet_id
      Schedule_name = "ansible-server-schedule"
      security_group_ids = [
        dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].security_group.app.id
      ]
      hosted_zones = {
        name    = "ssrs02.${dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].zones[local.vpc_name_abr].zone_name}"
        zone_id = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].zones[local.vpc_name_abr].zone_id
        type    = "A"
      }
    },
    {
      index            = "etl"
      name             = "etl-server"
      backup_plan_name = "${local.aws_account_name}-${local.region_context}-continous-backup"
      name_override    = "${upper(local.aws_account_name)}-${upper(local.vpc_name_abr)}-W-ETL-01"
      ami_config = {
        os_release_date  = "W22"
        os_base_packages = "BASE"
      }
      associate_public_ip_address = true
      instance_type               = "t3.large"
      iam_instance_profile        = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.ec2_profiles[local.vpc_name].iam_profiles.name
      associate_public_ip_address = true
      key_name                    = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.ec2_key_pairs["${local.vpc_name}-key-pair"].name
      custom_tags = merge(
        local.Misc_tags,
        {
          "Name"                = "${upper(local.aws_account_name)}-${upper(local.vpc_name_abr)}-W-ETL-01"
          "DNS_Prefix"          = "etl01"
          "CreateUser"          = "True"
          "WindowsBannerConfig" = "True"
        }
      )
      ebs_device_volume = {
        name                  = "xvdf"
        volume_size           = 30
        volume_type           = "gp3"
        delete_on_termination = true
      }
      ebs_root_volume = {
        volume_size           = 50
        volume_type           = "gp3"
        delete_on_termination = true
      }
      subnet_id     = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].public_subnet[include.env.locals.subnet_prefix.primary].primary_subnet_id
      Schedule_name = "ansible-server-schedule"
      security_group_ids = [
        dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].security_group.app.id
      ]
      hosted_zones = {
        name    = "etl01.${dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].zones[local.vpc_name_abr].zone_name}"
        zone_id = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].zones[local.vpc_name_abr].zone_id
        type    = "A"
      }
    }
  ]
  alb_listeners = [
    # {
    #   key             = "app"
    #   action          = "fixed-response"
    #   alb_arn         = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.load_balancers["app"].arn
    #   certificate_arn = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.certificates[local.vpc_name].arn
    #   protocol        = "HTTPS"
    #   port            = 443
    #   vpc_id          = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].vpc_id
    #   fixed_response = {
    #     content_type = "text/plain"
    #     message_body = "This is a default response from the ETL ALB listener."
    #     status_code  = "200"
    #   }
    # }
  ]
  alb_listener_rules = [
    # {
    #   index_key    = "app"
    #   listener_arn = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.load_balancers["app"].default_listener.arn
    #   rules = [
    #     {
    #       key      = "app"
    #       priority = 10
    #       type     = "forward"
    #       target_groups = [
    #         {
    #           tg_name = "${local.vpc_name_abr}-afr-tg"
    #           weight  = 99
    #         }
    #       ]
    #       conditions = [
    #         {
    #           host_headers = [
    #             "afrique.${local.public_hosted_zone}",
    #           ]
    #         }
    #       ]
    #     },
    #     {
    #       key      = "ecom"
    #       priority = 11
    #       type     = "forward"
    #       target_groups = [
    #         {
    #           tg_name = "${local.vpc_name_abr}-app2-tg"
    #           weight  = 99
    #         }
    #       ]
    #       conditions = [
    #         {
    #           host_headers = [
    #             "ecommerce.${local.public_hosted_zone}",
    #           ]
    #         }
    #       ]
    #     },
    #     {
    #       key      = "anime"
    #       priority = 12
    #       type     = "forward"
    #       target_groups = [
    #         {
    #           tg_name = "${local.vpc_name_abr}-app3-tg"
    #           weight  = 99
    #         }
    #       ]
    #       conditions = [
    #         {
    #           host_headers = [
    #             "anime.${local.public_hosted_zone}",
    #           ]
    #         }
    #       ]
    #     },
    #     {
    #       key      = "portainer"
    #       priority = 14
    #       type     = "forward"
    #       target_groups = [
    #         {
    #           tg_name = "${local.vpc_name_abr}-app4-tg"
    #           weight  = 99
    #         }
    #       ]
    #       conditions = [
    #         {
    #           host_headers = [
    #             "portainer.${local.public_hosted_zone}",
    #           ]
    #         }
    #       ]
    #     }
    #   ]
    # }
  ]
  nlb_listeners = [
    # {
    #   key             = "ssrs"
    #   nlb_key         = "ssrs-nlb"
    #   nlb_arn         = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.load_balancers["ssrs"].arn
    #   certificate_arn = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.certificates[local.vpc_name].arn
    #   protocol        = "TLS"
    #   port            = 443
    #   vpc_id          = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].vpc_id
    #   target_group = {
    #     name        = "${local.vpc_name_abr}-ssrs-tg"
    #     port        = 443
    #     protocol    = "TLS"
    #     target_type = "instance"
    #     attachments = [
    #       {
    #         ec2_key = "app"
    #         port    = 443
    #       }
    #     ]
    #     health_check = {
    #       protocol = "HTTPS"
    #       port     = 443
    #       path     = "/"
    #       matcher  = "200,401"
    #     }
    #   }
    # },
    # {
    #   key             = "ssrs"
    #   nlb_key         = "ssrs-nlb"
    #   nlb_arn         = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.load_balancers["ssrs"].arn
    #   certificate_arn = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.certificates[local.vpc_name].arn
    #   protocol        = "TLS"
    #   port            = 443
    #   vpc_id          = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].vpc_id
    #   target_group = {
    #     name        = "${local.vpc_name_abr}-ssrs-tg"
    #     port        = 8081
    #     protocol    = "TCP"
    #     target_type = "instance"
    #     attachments = []
    #     health_check = {
    #       protocol = "TCP"
    #       port     = 8081
    #     }
    #   }
    # }
  ]
  target_groups = [
    # {
    #   name        = "${local.vpc_name_abr}-app-tg"
    #   protocol    = "HTTP"
    #   port        = 8081
    #   target_type = "instance"
    #   health_check = {
    #     protocol = "HTTP"
    #     port     = "8081"
    #   }
    #   vpc_id = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].vpc_id
    # },
    # {
    #   name        = "${local.vpc_name_abr}-app2-tg"
    #   protocol    = "HTTP"
    #   port        = 8080
    #   target_type = "instance"
    #   health_check = {
    #     protocol = "HTTP"
    #     port     = "8080"
    #   }
    #   vpc_id = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].vpc_id
    # },
    # {
    #   name        = "${local.vpc_name_abr}-app3-tg"
    #   protocol    = "HTTP"
    #   port        = 8082
    #   target_type = "instance"
    #   health_check = {
    #     protocol = "HTTP"
    #     port     = "8082"
    #   }
    #   vpc_id = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].vpc_id
    # },
    # {
    #   name        = "${local.vpc_name_abr}-app4-tg"
    #   protocol    = "HTTP"
    #   port        = 8083
    #   target_type = "instance"
    #   health_check = {
    #     protocol            = "HTTP"
    #     port                = "8083"
    #     path                = "/"
    #     interval            = 30
    #     timeout             = 10
    #     healthy_threshold   = 2
    #     unhealthy_threshold = 3
    #     matcher             = "200-399"
    #   }
    #   vpc_id = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name_abr].vpc_id
    # },
    # {
    #   name        = "${local.vpc_name_abr}-ans-tg"
    #   protocol    = "HTTPS"
    #   port        = 443
    #   target_type = "instance"
    #   health_check = {
    #     protocol = "HTTPS"
    #     port     = "443"
    #     path     = "/"
    #   }
    #   vpc_id = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name].vpc_id
    # },
    # {
    #   name        = "${local.vpc_name_abr}-afr-tg"
    #   protocol    = "HTTP"
    #   port        = 3000
    #   target_type = "instance"
    #   health_check = {
    #     protocol            = "HTTP"
    #     port                = "3000"
    #     path                = "/"
    #     interval            = 30
    #     timeout             = 10
    #     healthy_threshold   = 2
    #     unhealthy_threshold = 3
    #     matcher             = "200-399"
    #   }
    #   vpc_id = dependency.shared_services.outputs.remote_tfstates.Shared.outputs.Account_products[local.vpc_name_abr].vpc_id
    # }
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


