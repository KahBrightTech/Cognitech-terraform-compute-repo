variable "common" {
  description = "Common variables used by all resources"
  type = object({
    global           = bool
    tags             = map(string)
    account_name     = string
    region_prefix    = string
    region           = string
    account_name_abr = optional(string)
  })
  default = null
}

variable "ec2_instances" {
  description = "EC2 Instance configuration"
  type = list(object({
    index             = optional(string)
    name              = string
    name_override     = optional(string)
    custom_ami        = optional(string)
    attach_tg         = optional(list(string))
    target_group_arns = optional(list(string))
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
    ebs_device_volume = optional(list(object({
      name                  = string
      volume_size           = number
      volume_type           = optional(string, "gp3")
      delete_on_termination = optional(bool, true)
      encrypted             = optional(bool, false)
      kms_key_id            = optional(string, null)
    })))
    subnet_id          = string
    Schedule_name      = optional(string)
    backup_plan_name   = optional(string)
    security_group_ids = list(string)
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

variable "alb_listeners" {
  description = "Load Balancer listener configuration"
  type = list(object({
    key              = optional(string)
    alb_arn          = optional(string)
    alb_key          = optional(string)
    action           = optional(string, "forward")
    port             = number
    protocol         = string
    ssl_policy       = optional(string)
    certificate_arn  = optional(string)
    alt_alb_hostname = optional(string)
    vpc_id           = optional(string)
    vpc_name         = optional(string)
    fixed_response = optional(object({
      content_type = optional(string, "text/plain")
      message_body = optional(string, "Oops! The page you are looking for does not exist.")
      status_code  = optional(string, "200")
    }))
    sni_certificates = optional(list(object({
      domain_name     = string
      certificate_arn = string
    })))
    target_group = optional(object({
      name         = optional(string)
      vpc_name_abr = optional(string)
      attachments = optional(list(object({
        target_id = optional(string)
        port      = optional(number)
      })))
      stickiness = optional(object({
        enabled         = optional(bool)
        type            = optional(string)
        cookie_duration = optional(number)
        cookie_name     = optional(string)
      }))
      health_check = optional(object({
        protocol = optional(string)
        port     = optional(number)
        path     = optional(string)
        matcher  = optional(string)
      }))
    }))
  }))
  default = null
}
variable "alb_listener_rules" {
  description = "ALB Listener Rule Configuration"
  type = list(object({
    index_key    = optional(string)
    listener_arn = optional(string)
    listener_key = optional(string)
    rules = list(object({
      key      = optional(string)
      priority = optional(number)
      type     = string
      target_groups = optional(list(object({
        tg_name = optional(string)
        arn     = optional(string)
        weight  = optional(number)
        port    = optional(number)
      })))
      conditions = optional(list(object({
        host_headers         = optional(list(string))
        http_request_methods = optional(list(string))
        path_patterns        = optional(list(string))
        source_ips           = optional(list(string))
        http_headers = optional(list(object({
          name   = optional(string)
          values = list(string)
        })))
        query_strings = optional(list(object({
          key   = optional(string)
          value = string
        })))
      })))
    }))
  }))
  default = null
}
variable "nlb_listeners" {
  description = "Network Load Balancer listener configuration"
  type = list(object({
    key             = optional(string)
    name            = optional(string)
    nlb_key         = optional(string)
    nlb_arn         = optional(string)
    action          = optional(string, "forward")
    port            = number
    protocol        = string
    ssl_policy      = optional(string)
    certificate_arn = optional(string)
    vpc_id          = optional(string)
    vpc_name        = optional(string)
    sni_certificates = optional(list(object({
      domain_name     = optional(string)
      certificate_arn = optional(string)
    })))
    target_group = optional(object({
      name         = optional(string)
      port         = optional(number)
      protocol     = optional(string)
      vpc_name_abr = optional(string)
      target_type  = optional(string)
      attachments = optional(list(object({
        target_id            = optional(string)
        port                 = optional(number)
        ec2_key              = optional(string)
        use_private_ip       = optional(bool, false) # If true, use private IP of the EC2 instance
        use_public_ip        = optional(bool, false) # If true, use public IP of the EC2 instance
        lambda_function_name = optional(string)      # Lambda function name for Lambda targets
      })))
      stickiness = optional(object({
        enabled         = optional(bool)
        type            = optional(string)
        cookie_duration = optional(number)
        cookie_name     = optional(string)
      }))
      health_check = object({
        enabled  = optional(bool, true)
        protocol = optional(string)
        port     = optional(number)
        path     = optional(string)
        matcher  = optional(string)
      })
    }))
  }))
  default = null
}

variable "target_groups" {
  description = "Target Group configuration"
  type = list(object({
    key                = optional(string)
    name               = string
    port               = number
    protocol           = string
    preserve_client_ip = optional(bool)
    target_type        = optional(string, "instance")
    tags               = optional(map(string))
    vpc_id             = optional(string)
    vpc_name           = optional(string)
    vpc_name_abr       = optional(string)
    attachments = optional(list(object({
      target_id = optional(string)
      port      = optional(number)
    })))
    stickiness = optional(object({
      enabled         = bool
      type            = string
      cookie_duration = optional(number)
      cookie_name     = optional(string)
    }))
    health_check = object({
      protocol = optional(string)
      port     = optional(number)
      path     = optional(string)
      matcher  = optional(string)
    })
  }))
  default = null
}


variable "launch_templates" {
  description = "Launch Template configuration"
  type = list(object({
    name             = string
    key              = string
    instance_profile = optional(string)
    custom_ami       = optional(string)
    ami_config = object({
      os_release_date  = optional(string)
      os_base_packages = optional(string)
    })
    instance_type               = optional(string)
    key_name                    = optional(string)
    associate_public_ip_address = optional(bool)
    vpc_security_group_ids      = optional(list(string))
    tags                        = optional(map(string))
    user_data                   = optional(string)
  }))
  default = null
}


variable "Autoscaling_groups" {
  description = "Auto Scaling configuration"
  type = list(object({
    name                      = optional(string)
    key                       = optional(string)
    min_size                  = optional(number)
    max_size                  = optional(number)
    health_check_type         = optional(string)
    health_check_grace_period = optional(number)
    force_delete              = optional(bool)
    desired_capacity          = optional(number)
    subnet_ids                = optional(list(string))
    launch_template_name      = optional(string)
    launch_template = optional(object({
      id      = string
      version = optional(string, "$Latest")
    }))
    attach_target_groups = optional(list(string))
    timeouts = optional(object({
      delete = optional(string)
    }))
    tags = optional(map(string))
    additional_tags = optional(list(object({
      key                 = string
      value               = string
      propagate_at_launch = optional(bool, true)
    })))
  }))
  default = null
}

variable "dr_volume_restores" {
  description = "Disaster Recovery Volume Restore configuration"
  type = list(object({
    name                 = optional(string)
    source_instance_name = string
    target_instance_name = string
    target_az            = string
    device_volumes = list(object({
      device_name = string
      size        = optional(number) # Size in GB, if not specified uses snapshot size
    }))
    restore_volume_tags = map(string)
    account_id          = string
  }))
  default = null
}
