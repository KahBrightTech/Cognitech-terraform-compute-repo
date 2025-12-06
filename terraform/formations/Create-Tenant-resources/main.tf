
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
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/EC2-instance?ref=v1.3.34"
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
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/nlb-listener?ref=v1.3.25"
  for_each = (var.nlb_listeners != null) ? { for item in var.nlb_listeners : item.key => item } : {}
  common   = var.common
  nlb_listener = merge(
    each.value,
    {
      target_group = each.value.target_group != null ? merge(
        each.value.target_group,
        {
          # Only process attachments if they exist and are not empty
          attachments = (each.value.target_group.attachments != null && length(each.value.target_group.attachments) > 0) ? [
            for item in each.value.target_group.attachments :
            merge(
              item,
              {
                target_id = item.ec2_key != null ? module.ec2_instance[item.ec2_key].instance_id : item.target_id
              }
            )
          ] : []
        }
      ) : null
    }
  )
}

#--------------------------------------------------------------------
# Creates Launch template
# #--------------------------------------------------------------------
module "launch_templates" {
  source          = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Launch_template?ref=v1.4.30"
  for_each        = (var.launch_templates != null) ? { for item in var.launch_templates : item.name => item } : {}
  common          = var.common
  launch_template = each.value
}

#--------------------------------------------------------------------
# Creates Auto Scaling Group
# #--------------------------------------------------------------------
module "auto_scaling_groups" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/AutoScaling?ref=v1.3.24"
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
    # Convert target group names to ARNs if attach_target_groups is specified
    each.value.attach_target_groups != null ? {
      attach_target_groups = compact([
        for tg_name in each.value.attach_target_groups :
        # Check if it's a standalone target group first
        contains(keys(module.target_groups), tg_name) ?
        module.target_groups[tg_name].target_group_arn :
        # Check if it's an NLB listener target group by finding a listener with matching target group name
        length([
          for listener in var.nlb_listeners :
          listener.key if listener.target_group != null && listener.target_group.name == tg_name
        ]) > 0 ?
        module.nlb_listeners[[
          for listener in var.nlb_listeners :
          listener.key if listener.target_group != null && listener.target_group.name == tg_name
        ][0]].nlb_target_group_arn :
        # If not found in either, return null (will be filtered out by compact)
        null
      ])
    } : {}
  )
  depends_on = [module.launch_templates, module.target_groups, module.nlb_listeners]
}

#--------------------------------------------------------------------
# EBS Recovery
# #--------------------------------------------------------------------
module "ebs_recovery" {
  source            = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/EBSRecovery?ref=v1.3.45"
  for_each          = (var.dr_volume_restores != null) ? { for item in var.dr_volume_restores : item.key => item } : {}
  common            = var.common
  dr_volume_restore = each.value
}


#--------------------------------------------------------------------
# EKS Worker nodes
# #--------------------------------------------------------------------
module "eks_worker_nodes" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/EKS-Node-group?ref=v1.4.27"
  for_each = (var.eks_nodes != null) ? { for item in var.eks_nodes : item.key => item } : {}
  common   = var.common
  eks_node_group = merge(
    each.value,
    each.value.use_launch_template ? {
      launch_template = {
        id      = module.launch_templates[each.value.launch_template_name].id
        version = "$Latest"
      }
    } : {}
  )
}
