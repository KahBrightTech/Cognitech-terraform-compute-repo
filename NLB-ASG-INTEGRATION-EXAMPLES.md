# NLB Listener with Target Group (No Attachments) + ASG Configuration

This example shows how to create an NLB listener with a target group that has no initial attachments, and then reference that target group in an Auto Scaling Group configuration.

## Configuration Example

```hcl
# 1. Create Launch Template for ASG
launch_templates = [
  {
    name             = "web-app-lt"
    key              = "web-app-key"
    instance_type    = "t3.medium"
    key_name         = "my-key-pair"
    ami_config = {
      os_release_date  = "2024-01-01"
      os_base_packages = "minimal"
    }
    associate_public_ip_address = false
    vpc_security_group_ids      = ["sg-12345678"]
    user_data                   = base64encode(<<-EOF
      #!/bin/bash
      yum update -y
      yum install -y httpd
      systemctl start httpd
      systemctl enable httpd
      echo "<h1>Hello from Auto Scaling Group</h1>" > /var/www/html/index.html
    EOF
    )
  }
]

# 2. Create NLB Listener with Target Group (NO attachments)
nlb_listeners = [
  {
    key      = "web-nlb-listener"
    name     = "web-listener"
    nlb_arn  = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/net/my-web-nlb/50dc6c495c0c9188"
    port     = 80
    protocol = "TCP"
    
    # Create target group without any initial attachments
    target_group = {
      name         = "web-app-nlb-tg"
      port         = 80
      protocol     = "TCP"
      vpc_name_abr = "main"
      target_type  = "instance"
      
      # No attachments - leave empty or omit entirely
      attachments = []
      
      health_check = {
        enabled  = true
        protocol = "TCP"
        port     = 80
      }
    }
  }
]

# 3. Create Auto Scaling Group that references the NLB listener's target group
Autoscaling_groups = [
  {
    name                      = "web-app-asg"
    min_size                  = 2
    max_size                  = 10
    desired_capacity          = 3
    health_check_type         = "ELB"
    health_check_grace_period = 300
    subnet_ids                = ["subnet-12345", "subnet-67890"]
    launch_template_name      = "web-app-lt"
    
    # Reference the NLB listener key to attach to its target group
    attach_target_groups = ["web-nlb-listener"]
    
    tags = {
      Environment = "production"
      Application = "web-app"
    }
  }
]
```

## Alternative: Using Standalone Target Groups

If you prefer to create standalone target groups first:

```hcl
# 1. Create standalone target group
target_groups = [
  {
    name         = "standalone-web-tg"
    port         = 80
    protocol     = "TCP"
    vpc_name_abr = "main"
    target_type  = "instance"
    
    # No attachments needed
    attachments = []
    
    health_check = {
      protocol = "TCP"
      port     = 80
    }
  }
]

# 2. Create NLB listener that uses existing target group
nlb_listeners = [
  {
    key                        = "web-listener-existing-tg"
    nlb_arn                   = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/net/my-nlb/50dc6c495c0c9188"
    port                      = 80
    protocol                  = "TCP"
    existing_target_group_name = "standalone-web-tg"  # Reference existing target group
  }
]

# 3. ASG references the standalone target group
Autoscaling_groups = [
  {
    name                 = "web-app-asg"
    min_size            = 2
    max_size            = 10
    desired_capacity    = 3
    launch_template_name = "web-app-lt"
    subnet_ids          = ["subnet-12345", "subnet-67890"]
    
    # Reference the standalone target group
    attach_target_groups = ["standalone-web-tg"]
  }
]
```

## Multi-Service Example

```hcl
# Multiple services with different NLB listeners and ASGs
nlb_listeners = [
  {
    key      = "frontend-listener"
    nlb_arn  = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/net/my-nlb/50dc6c495c0c9188"
    port     = 80
    protocol = "TCP"
    target_group = {
      name         = "frontend-tg"
      port         = 80
      protocol     = "TCP"
      vpc_name_abr = "main"
      target_type  = "instance"
      attachments  = []  # No initial attachments
      health_check = {
        enabled  = true
        protocol = "TCP"
        port     = 80
      }
    }
  },
  {
    key      = "backend-listener"
    nlb_arn  = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/net/my-nlb/50dc6c495c0c9188"
    port     = 8080
    protocol = "TCP"
    target_group = {
      name         = "backend-tg"
      port         = 8080
      protocol     = "TCP"
      vpc_name_abr = "main"
      target_type  = "instance"
      attachments  = []  # No initial attachments
      health_check = {
        enabled  = true
        protocol = "TCP"
        port     = 8080
      }
    }
  }
]

# ASGs for different services
Autoscaling_groups = [
  {
    name                 = "frontend-asg"
    min_size            = 2
    max_size            = 8
    desired_capacity    = 3
    launch_template_name = "frontend-lt"
    subnet_ids          = ["subnet-12345", "subnet-67890"]
    attach_target_groups = ["frontend-listener"]  # Reference NLB listener key
  },
  {
    name                 = "backend-asg"
    min_size            = 1
    max_size            = 5
    desired_capacity    = 2
    launch_template_name = "backend-lt"
    subnet_ids          = ["subnet-12345", "subnet-67890"]
    attach_target_groups = ["backend-listener"]   # Reference NLB listener key
  }
]
```

## Key Benefits of This Approach

1. **Clean Separation**: NLB listener defines the target group, ASG manages the instances
2. **Automatic Management**: ASG automatically adds/removes instances from the target group
3. **Health Checks**: ELB health checks work seamlessly with ASG health checks
4. **Scaling**: When ASG scales up/down, instances are automatically registered/deregistered
5. **Flexibility**: Can reference either NLB listener target groups or standalone target groups

## Important Notes

- Set `health_check_type = "ELB"` in ASG to use load balancer health checks
- Set `health_check_grace_period` to allow time for instances to become healthy
- The ASG will automatically register new instances with the target group
- Use the NLB listener `key` in the ASG `attach_target_groups` list to reference the target group created by that listener
- Alternatively, use standalone target group names for more explicit control