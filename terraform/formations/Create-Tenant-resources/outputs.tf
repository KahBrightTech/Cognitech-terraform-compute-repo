
#-------------------------------------------------------
# EC2 module output
#-------------------------------------------------------
output "ec2" {
  description = "The EC2 instance details"
  value       = module.ec2_instance
}

#-------------------------------------------------------
# Route 53 module output  
#-------------------------------------------------------

output "hosted_zones" {
  description = "The Route 53 hosted zones details"
  value       = module.hosted_zones

}

#-------------------------------------------------------
# ALB listener outputs
#-------------------------------------------------------
output "alb_listeners" {
  description = "Output for ALB Listeners"
  value       = module.alb_listeners
}

#-------------------------------------------------------
# ALB listener rules outputs
#-------------------------------------------------------
output "alb_listener_rules" {
  description = "Output for ALB Listener Rules"
  value       = (var.alb_listener_rules != null) ? module.alb_listener_rules : null
}

#-------------------------------------------------------
# NLB listener outputs
#-------------------------------------------------------
output "nlb_listeners" {
  description = "Output for NLB Listeners"
  value       = module.nlb_listeners
}

#-------------------------------------------------------
# Target Group outputs  
#-------------------------------------------------------
output "target_groups" {
  description = "Output for Target Groups"
  value       = module.target_groups
}

#-------------------------------------------------------
# Launch Template outputs
#-------------------------------------------------------
output "launch_templates" {
  description = "Output for Launch Templates"
  value       = module.launch_templates
}

#-------------------------------------------------------
# Autoscaling groups outputs
#-------------------------------------------------------
output "auto_scaling_groups" {
  description = "Output for Auto Scaling Groups"
  value       = module.auto_scaling_groups
}
