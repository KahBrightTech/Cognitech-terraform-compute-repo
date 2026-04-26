
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
# NLB listener debug output
#-------------------------------------------------------
output "nlb_listeners_debug" {
  description = "Debug output for NLB Listeners structure"
  value = var.nlb_listeners != null ? {
    for listener in var.nlb_listeners :
    listener.key => {
      config        = listener
      module_output = try(module.nlb_listeners[listener.key], "not_found")
    }
  } : {}
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

#-------------------------------------------------------
# DR volume restores outputs
#-------------------------------------------------------
output "dr_volume_restores" {
  description = "Output for DR Volume Restores"
  value       = module.ebs_recovery
}

#-------------------------------------------------------
# EKS Worker nodes outputs
#-------------------------------------------------------
output "eks_worker_nodes" {
  description = "Output for EKS Worker Nodes"
  value       = module.eks_worker_nodes
}

#-------------------------------------------------------
# EKS Service accounts outputs
#-------------------------------------------------------
output "eks_service_accounts" {
  description = "Output for EKS Service Accounts"
  value       = module.eks_service_accounts
}