
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
module "ec2" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/EC2-instance?ref=v1.1.79"
  for_each = (var.ec2s != null) ? { for item in var.ec2s : item.index => item } : {}
  common   = var.common
  ec2      = each.value
}


#--------------------------------------------------------------------
# Route 53 - Creates  DNS records 
#--------------------------------------------------------------------
module "hosted_zones" {
  source   = "git::https://github.com/njibrigthain100/Cognitech-terraform-iac-modules.git//terraform/modules/Route-53-records?ref=v1.1.80"
  for_each = (var.ec2s != null) ? { for item in var.ec2s : item.index => item if item.hosted_zones != null } : {}
  common   = var.common
  dns_record = merge(
    each.value.hosted_zones,
    {
      records = [module.ec2[each.key].private_ip]
    }
  )
}






