
#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_iam_roles" "admin_role" {
  name_regex  = "AWSReservedSSO_AdministratorAccess_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_iam_roles" "network_role" {
  name_regex  = "AWSReservedSSO_NetworkAdministrator_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

#--------------------------------------------------------------------
# Target groups 
#--------------------------------------------------------------------
module "target_groups" {
  source = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Target-groups?ref=v1.3.9"
  #for_each     = (var.target_groups != null) ? { for item in var.target_groups : (item.key != null ? item.key : item.name) => item } : {}
  for_each     = (var.target_groups != null) ? { for item in var.target_groups : item.name => item } : {}
  common       = var.common
  target_group = each.value
}

#--------------------------------------------------------------------
# EC2 - Creates ec2 instances
#--------------------------------------------------------------------
module "ec2_instance" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/EC2-instance?ref=v1.3.11"
  for_each = (var.ec2_instances != null) ? { for item in var.ec2_instances : item.index => item } : {}
  common   = var.common
  ec2 = merge(
    each.value,
    {
      target_group_arns = (each.value.attach_tg != null) ? [
        for item in each.value.attach_tg :
        module.target_groups[item].target_group_arn
      ] : null
    }
  )
}


#--------------------------------------------------------------------
# Route 53 - Creates  DNS records 
#--------------------------------------------------------------------
module "hosted_zones" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Route-53-records?ref=v1.1.81"
  for_each = (var.ec2_instances != null) ? { for item in var.ec2_instances : item.index => item if item.hosted_zones != null } : {}
  common   = var.common
  dns_record = merge(
    each.value.hosted_zones,
    {
      records = [module.ec2_instance[each.key].private_ip]
    }
  )
}

#--------------------------------------------------------------------
# ALB listeners
#--------------------------------------------------------------------
module "alb_listeners" {
  source = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/alb-listeners?ref=v1.3.1"
  for_each = (var.alb_listeners != null) ? {
    for item in var.alb_listeners : item.key => item
  } : {}
  common       = var.common
  alb_listener = each.value
}

#--------------------------------------------------------------------
# ALB listener rules
#--------------------------------------------------------------------
module "alb_listener_rules" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/alb-listener-rule?ref=v1.3.1"
  for_each = (var.alb_listener_rules != null) ? { for item in var.alb_listener_rules : item.index_key => item } : {}
  common   = var.common
  rule = [
    for item in each.value.rules : merge(
      item,
      {
        listener_arn = each.value.listener_key != null ? module.alb_listeners[each.value.listener_key].alb_listener_arn : each.value.listener_arn
        target_groups = [
          for tg in item.target_groups :
          {
            arn    = tg.tg_name != null ? module.target_groups[tg.tg_name].target_group_arn : tg.arn
            weight = tg.weight
          }
        ]
      }
    )
  ]
}

#--------------------------------------------------------------------
# NLB listeners
#--------------------------------------------------------------------
module "nlb_listeners" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/nlb-listener?ref=v1.3.1"
  for_each = (var.nlb_listeners != null) ? { for item in var.nlb_listeners : item.key => item } : {}
  common   = var.common
  nlb_listener = merge(
    each.value,
    {
      target_group = each.value.target_group != null ? merge(
        each.value.target_group,
        {
          attachments = [
            for item in each.value.target_group.attachments :
            merge(
              item,
              {
                target_id = item.ec2_key != null ? module.ec2_instance[item.ec2_key].instance_id : item.target_id
              }
            )
          ]
        }
      ) : null
    }
  )
}

#--------------------------------------------------------------------
# Creates Launch template
# #--------------------------------------------------------------------
module "launch_templates" {
  source          = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Launch_template?ref=v1.3.21"
  for_each        = (var.launch_templates != null) ? { for item in var.launch_templates : item.name => item } : {}
  common          = var.common
  launch_template = each.value
}

#--------------------------------------------------------------------
# Creates Auto Scaling Group
# #--------------------------------------------------------------------
module "auto_scaling_groups" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/AutoScaling?ref=v1.3.21"
  for_each = (var.Autoscaling_groups != null) ? { for item in var.Autoscaling_groups : item.name => item } : {}
  common   = var.common
  Autoscaling_group = merge(
    each.value,
    {
      launch_template = {
        id      = module.launch_templates[each.value.launch_template_name].id
        version = "$Latest"
      }
    },
    # Only include attach_target_groups if it's available
    can(module.target_groups[each.value.key].arn) ? {
      attach_target_groups = module.target_groups[each.value.key].arn
      } : (each.value.attach_target_groups != null ? {
        attach_target_groups = each.value.attach_target_groups
    } : {})
  )

  depends_on = [module.launch_templates]
}

#--------------------------------------------------------------------
# EBS Restores
#--------------------------------------------------------------------
module "ebs_restores" {
  source      = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Restore-volume?ref=v1.3.22"
  for_each    = (var.ebs_restores != null) ? { for item in var.ebs_restores : item.key => item } : {}
  common      = var.common
  ebs_restore = each.value
}




