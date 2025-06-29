
#-------------------------------------------------------
# S3 bucket outputs
#-------------------------------------------------------
output "ec2" {
  description = "The EC2 instance details"
  value       = module.ec2
}

