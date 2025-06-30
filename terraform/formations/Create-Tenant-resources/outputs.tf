
#-------------------------------------------------------
# EC2 module output
#-------------------------------------------------------
output "ec2" {
  description = "The EC2 instance details"
  value       = module.ec2
}

#-------------------------------------------------------
# Route 53 module output  
#-------------------------------------------------------

output "hosted_zones" {
  description = "The Route 53 hosted zones details"
  value       = module.hosted_zones

}
