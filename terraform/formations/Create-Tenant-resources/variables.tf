variable "common" {
  description = "Common variables used by all resources"
  type = object({
    global        = bool
    tags          = map(string)
    account_name  = string
    region_prefix = string
    region        = string
  })
  default = null
}

variable "ec2s" {
  description = "EC2 Instance configuration"
  type = list(object({
    description = "EC2 Instance configuration"
    type = object({
      name          = string
      name_override = optional(string)
      custom_ami    = optional(string)
      ami_config = object({
        os_release_date  = optional(string)
        os_base_packages = optional(string)
      })
      associate_public_ip_address = optional(bool, false)
      instance_type               = string
      iam_instance_profile        = string
      key_name                    = string
      custom_tags                 = optional(map(string))
      ebs_root_volume = optional(object({
        volume_size           = number
        volume_type           = optional(string, "gp3")
        delete_on_termination = optional(bool, true)
        encrypted             = optional(bool, false)
        kms_key_id            = optional(string, null)
      }))
      ebs_device_volume = optional(object({
        name                  = string
        volume_size           = number
        volume_type           = optional(string, "gp3")
        delete_on_termination = optional(bool, true)
        encrypted             = optional(bool, false)
        kms_key_id            = optional(string, null)
      }))
      subnet_id          = string
      Schedule_name      = optional(string)
      backup_plan_name   = optional(string)
      security_group_ids = list(string)
    })
    hosted_zones = optional(object({
      name           = string
      zone_id        = string
      type           = string
      ttl            = optional(number, 60)
      records        = optional(list(string))
      set_identifier = optional(string)
      weight         = optional(number)
    }))
  }))
  default = null
}


