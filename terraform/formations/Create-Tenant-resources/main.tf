
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
# EC2 - Creates ec2 instances
#--------------------------------------------------------------------
module "ec2_instance" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/EC2-instance?ref=v1.2.99"
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
# Target groups
#--------------------------------------------------------------------
module "target_groups" {
  source       = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Target-groups?ref=v1.2.99"
  for_each     = (var.target_groups != null) ? { for item in var.target_groups : item.key => item } : {}
  common       = var.common
  target_group = each.value
}

#--------------------------------------------------------------------
# ALB listeners
#--------------------------------------------------------------------
module "alb_listeners" {
  source = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/alb-listeners?ref=v1.2.99"
  for_each = (var.alb_listeners != null) ? {
    for item in var.alb_listeners : item.key => item
  } : {}
  common = var.common
  alb_listener = merge(
    each.value,
    {
      target_group = try(each.value.target_group, null) != null ? merge(
        each.value.target_group,
        {
          attachments = each.value.target_group.attachments != null ? each.value.target_group.attachments : []
        }
      ) : null
    }
  )
}

#--------------------------------------------------------------------
# ALB listener rules
#--------------------------------------------------------------------
module "alb_listener_rules" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/alb-listener-rule?ref=v1.2.99"
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
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/nlb-listener?ref=v1.2.99"
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





