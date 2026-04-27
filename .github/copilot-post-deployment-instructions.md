# Copilot Instructions for Post-Deployment Configuration

## Variables — CHANGE THESE PER DEPLOYMENT

Update the values below before running post-deployment tasks. These reference the account where resources were deployed.

```
ACCOUNT_NAME:           int-production
ACCOUNT_ABR:            intp
ACCOUNT_ID:             271457809232
IAM_ROLE:               arn:aws:iam::271457809232:role/int-prod-OIDCGitHubRole-role
PRIMARY_REGION:         us-east-1
SECONDARY_REGION:       us-west-2
VPC_NAME:               shared-services
VPC_NAME_ABR:           shared
INSTANCE_TAG_PATTERN:   INTP-SHARED-*
ENVIRONMENT_TAG_KEY:    Environment
ENVIRONMENT_TAG_VALUE:  Shared
SSM_DOCUMENT_NAME:      <YOUR-SSM-DOCUMENT-NAME>
SSM_DOCUMENT_WINDOWS:   intp-use1-Windows-Banner-Config
SSM_DOCUMENT_LINUX:     <YOUR-LINUX-SSM-DOCUMENT>
```

> **NOTE**: Instances are filtered by `<ENVIRONMENT_TAG_KEY>=<ENVIRONMENT_TAG_VALUE>` tag (default: `Environment=Shared`). The INSTANCE_TAG_PATTERN is kept for reference only.

> **SSM_DOCUMENT_NAME**: General SSM document to run on all instances (optional if using OS-specific documents).

> **SSM_DOCUMENT_WINDOWS**: SSM document specifically for Windows instances (default: `intp-use1-Windows-Banner-Config`).

> **SSM_DOCUMENT_LINUX**: SSM document specifically for Linux instances. Use `AWS-RunShellScript` for ad-hoc commands.

### Quick-reference: values for other accounts

**int-preproduction:**
```
ACCOUNT_NAME:           int-preproduction
ACCOUNT_ABR:            intpp
ACCOUNT_ID:             730335294148
IAM_ROLE:               arn:aws:iam::730335294148:role/int-OIDCGitHubRole-role
PRIMARY_REGION:         us-east-1
SECONDARY_REGION:       us-west-2
VPC_NAME:               shared-services
VPC_NAME_ABR:           shared
INSTANCE_TAG_PATTERN:   INTPP-SHARED-*
ENVIRONMENT_TAG_KEY:    Environment
ENVIRONMENT_TAG_VALUE:  Shared
SSM_DOCUMENT_WINDOWS:   intpp-use1-Windows-Banner-Config
SSM_DOCUMENT_LINUX:     <YOUR-LINUX-SSM-DOCUMENT>
```

**md-preproduction:**
```
ACCOUNT_NAME:           md-preproduction
ACCOUNT_ABR:            mdpp
ACCOUNT_ID:             533267408704
IAM_ROLE:               arn:aws:iam::533267408704:role/<YOUR-OIDC-ROLE>
PRIMARY_REGION:         us-east-1
SECONDARY_REGION:       us-west-2
VPC_NAME:               shared-services
VPC_NAME_ABR:           shared
INSTANCE_TAG_PATTERN:   MDPP-SHARED-*
ENVIRONMENT_TAG_KEY:    Environment
ENVIRONMENT_TAG_VALUE:  Shared
SSM_DOCUMENT_WINDOWS:   mdpp-use1-Windows-Banner-Config
SSM_DOCUMENT_LINUX:     <YOUR-LINUX-SSM-DOCUMENT>
```

**md-production:**
```
ACCOUNT_NAME:           md-production
ACCOUNT_ABR:            mdp
ACCOUNT_ID:             388927731914
IAM_ROLE:               arn:aws:iam::388927731914:role/<YOUR-OIDC-ROLE>
PRIMARY_REGION:         us-east-1
SECONDARY_REGION:       us-west-2
VPC_NAME:               shared-services
VPC_NAME_ABR:           shared
INSTANCE_TAG_PATTERN:   MDP-SHARED-*
ENVIRONMENT_TAG_KEY:    Environment
ENVIRONMENT_TAG_VALUE:  Shared
SSM_DOCUMENT_WINDOWS:   mdp-use1-Windows-Banner-Config
SSM_DOCUMENT_LINUX:     <YOUR-LINUX-SSM-DOCUMENT>
```

---

## Overview

This document provides instructions for **post-deployment configuration** of AWS EC2 instances after terraform apply has successfully completed. Use this to run existing SSM documents on newly provisioned servers.

**Prerequisites:**
- Terraform apply has completed successfully
- EC2 instances are running with SSM agent installed
- Instances have IAM role with `AmazonSSMManagedInstanceCore` policy
- AWS CLI is configured with appropriate credentials

---

## How to Run SSM Document on New Servers

Follow these steps to execute an existing SSM document on newly deployed instances:

### Step 1: Verify the Variables

Ensure the variables above are set correctly for your target account:
- `ENVIRONMENT_TAG_KEY` and `ENVIRONMENT_TAG_VALUE` define the tag to filter instances (default: `Environment=Shared`)
- `PRIMARY_REGION` specifies where to search for instances
- `IAM_ROLE` (used if configuring AWS CLI with OIDC)
- `SSM_DOCUMENT_NAME` is the name of your existing SSM document

### Step 2: Check if Instances are Running

```powershell
# Configure AWS credentials (choose one method)
$env:AWS_PROFILE = "<profile-name>"
# OR use the IAM role (requires AWS CLI configured for OIDC)

# Find instances by tag
aws ec2 describe-instances `
  --filters "Name=tag:<ENVIRONMENT_TAG_KEY>,Values=<ENVIRONMENT_TAG_VALUE>" `
            "Name=instance-state-name,Values=running" `
  --region <PRIMARY_REGION> `
  --query "Reservations[*].Instances[*].[InstanceId,Tags[?Key=='Name'].Value|[0],State.Name,PrivateIpAddress]" `
  --output table
```

**Example for int-production:**
```powershell
aws ec2 describe-instances `
  --filters "Name=tag:Environment,Values=Shared" `
            "Name=instance-state-name,Values=running" `
  --region us-east-1 `
  --query "Reservations[*].Instances[*].[InstanceId,Tags[?Key=='Name'].Value|[0],State.Name,PrivateIpAddress]" `
  --output table
```

**Example with custom tag:**
```powershell
aws ec2 describe-instances `
  --filters "Name=tag:Deployment,Values=Production" `
            "Name=instance-state-name,Values=running" `
  --region us-east-1 `
  --query "Reservations[*].Instances[*].[InstanceId,Tags[?Key=='Name'].Value|[0],State.Name,PrivateIpAddress]" `
  --output table
```

### Step 3: Check SSM Connectivity and Get OS Information

```powershell
# Get instance IDs
$instanceIds = aws ec2 describe-instances `
  --filters "Name=tag:<ENVIRONMENT_TAG_KEY>,Values=<ENVIRONMENT_TAG_VALUE>" `
            "Name=instance-state-name,Values=running" `
  --region <PRIMARY_REGION> `
  --query "Reservations[*].Instances[*].InstanceId" `
  --output text

# Check SSM status and OS type for each instance
$instanceInfo = @()
foreach ($id in $instanceIds -split '\s+') {
  $info = aws ssm describe-instance-information `
    --filters "Key=InstanceIds,Values=$id" `
    --region <PRIMARY_REGION> `
    --query "InstanceInformationList[0].[InstanceId,PingStatus,PlatformType]" `
    --output json | ConvertFrom-Json
  
  if ($info) {
    $instanceInfo += [PSCustomObject]@{
      InstanceId = $info[0]
      PingStatus = $info[1]
      PlatformType = $info[2]
    }
    Write-Host "$($info[0]): Status=$($info[1]), OS=$($info[2])"
  }
}

# Separate instances by OS type
$windowsInstances = ($instanceInfo | Where-Object { $_.PlatformType -eq "Windows" -and $_.PingStatus -eq "Online" }).InstanceId
$linuxInstances = ($instanceInfo | Where-Object { $_.PlatformType -eq "Linux" -and $_.PingStatus -eq "Online" }).InstanceId

Write-Host "`nWindows instances: $windowsInstances"
Write-Host "Linux instances: $linuxInstances"
```

**Verify PingStatus = "Online"** before proceeding.

### Step 4: Run SSM Documents Based on OS Type

```powershell
# Run Windows-specific SSM document
if ($windowsInstances) {
  Write-Host "`n=== Running Windows SSM Document ==="
  $winCommandId = aws ssm send-command `
    --instance-ids $windowsInstances `
    --document-name "<SSM_DOCUMENT_WINDOWS>" `
    --region <PRIMARY_REGION> `
    --comment "Windows configuration after terraform deployment" `
    --query "Command.CommandId" `
    --output text
  
  Write-Host "Windows Command ID: $winCommandId"
}

# Run Linux-specific SSM document
if ($linuxInstances) {
  Write-Host "`n=== Running Linux SSM Document ==="
  $linuxCommandId = aws ssm send-command `
    --instance-ids $linuxInstances `
    --document-name "<SSM_DOCUMENT_LINUX>" `
    --region <PRIMARY_REGION> `
    --comment "Linux configuration after terraform deployment" `
    --query "Command.CommandId" `
    --output text
  
  Write-Host "Linux Command ID: $linuxCommandId"
}

# Wait for Windows command to complete
if ($windowsInstances -and $winCommandId) {
  Write-Host "`nWaiting for Windows command to complete..."
  $firstWinInstance = ($windowsInstances -split '\s+')[0]
  aws ssm wait command-executed `
    --command-id $winCommandId `
    --instance-id $firstWinInstance `
    --region <PRIMARY_REGION>
  
  # Get results for each Windows instance
  foreach ($id in $windowsInstances -split '\s+') {
    Write-Host "`n=== Windows Results for $id ==="
    aws ssm get-command-invocation `
      --command-id $winCommandId `
      --instance-id $id `
      --region <PRIMARY_REGION> `
      --query '[Status,StandardOutputContent,StandardErrorContent]' `
      --output text
  }
}

# Wait for Linux command to complete
if ($linuxInstances -and $linuxCommandId) {
  Write-Host "`nWaiting for Linux command to complete..."
  $firstLinuxInstance = ($linuxInstances -split '\s+')[0]
  aws ssm wait command-executed `
    --command-id $linuxCommandId `
    --instance-id $firstLinuxInstance `
    --region <PRIMARY_REGION>
  
  # Get results for each Linux instance
  foreach ($id in $linuxInstances -split '\s+') {
    Write-Host "`n=== Linux Results for $id ==="
    aws ssm get-command-invocation `
      --command-id $linuxCommandId `
      --instance-id $id `
      --region <PRIMARY_REGION> `
      --query '[Status,StandardOutputContent,StandardErrorContent]' `
      --output text
  }
}
```

**Example for int-production with OS detection:**
```powershell
$instanceIds = aws ec2 describe-instances `
  --filters "Name=tag:Environment,Values=Shared" `
            "Name=instance-state-name,Values=running" `
  --region us-east-1 `
  --query "Reservations[*].Instances[*].InstanceId" `
  --output text

# Get OS type for each instance
$instanceInfo = @()
foreach ($id in $instanceIds -split '\s+') {
  $info = aws ssm describe-instance-information `
    --filters "Key=InstanceIds,Values=$id" `
    --region us-east-1 `
    --query "InstanceInformationList[0].[InstanceId,PlatformType]" `
    --output json | ConvertFrom-Json
  
  if ($info) {
    $instanceInfo += [PSCustomObject]@{
      InstanceId = $info[0]
      PlatformType = $info[1]
    }
  }
}

# Run Windows document
$windowsInstances = ($instanceInfo | Where-Object { $_.PlatformType -eq "Windows" }).InstanceId
if ($windowsInstances) {
  $winCommandId = aws ssm send-command `
    --instance-ids $windowsInstances `
    --document-name "intp-use1-Windows-Banner-Config" `
    --region us-east-1 `
    --query "Command.CommandId" `
    --output text

  Write-Host "Windows Command ID: $winCommandId"
}

# Run Linux document
$linuxInstances = ($instanceInfo | Where-Object { $_.PlatformType -eq "Linux" }).InstanceId
if ($linuxInstances) {
  $linuxCommandId = aws ssm send-command `
    --instance-ids $linuxInstances `
    --document-name "AWS-RunShellScript" `
    --region us-east-1 `
    --parameters 'commands=["echo Configuration complete"]' `
    --query "Command.CommandId" `
    --output text
  Write-Host "Linux Command ID: $linuxCommandId"
}
```
  --document-name "MyApp-Deploy" `
  --region us-east-1 `
  --query "Command.CommandId" `
  --output text
```

### Step 5: If SSM Document Requires Parameters

If your SSM document expects parameters, pass them conditionally based on OS:

```powershell
# For Windows instances with parameters
if ($windowsInstances) {
  $winCommandId = aws ssm send-command `
    --instance-ids $windowsInstances `
    --document-name "<SSM_DOCUMENT_WINDOWS>" `
    --parameters '{"param1":["value1"],"param2":["value2"]}' `
    --region <PRIMARY_REGION> `
    --query "Command.CommandId" `
    --output text
}

# For Linux instances with parameters
if ($linuxInstances) {
  $linuxCommandId = aws ssm send-command `
    --instance-ids $linuxInstances `
    --document-name "<SSM_DOCUMENT_LINUX>" `
    --parameters '{"commands":["sudo yum update -y","sudo systemctl restart app"]}' `
    --region <PRIMARY_REGION> `
    --query "Command.CommandId" `
    --output text
}
```

---

## Important Notes

- **Always verify instance state** before running commands
- **Check SSM connectivity** (PingStatus = "Online") before sending commands
- **OS detection** automatically separates Windows and Linux instances for targeted configuration
- **Review command output** for each instance to ensure success
- **SSM agent** must be running on instances (pre-installed on modern AMIs)
- **IAM permissions** required: EC2 instances need `AmazonSSMManagedInstanceCore` policy
- **Document naming convention**: Use OS-specific documents for better control (e.g., `intp-use1-Windows-Banner-Config`)

---

## Troubleshooting

**Instances not found:**
- Verify instances have the tag defined by `ENVIRONMENT_TAG_KEY=ENVIRONMENT_TAG_VALUE` (default: `Environment=Shared`)
- Check that you're searching in the correct region
- Confirm instances are in "running" state

**SSM connectivity issues:**
- Verify SSM agent is running: Check Systems Manager → Fleet Manager
- Ensure IAM role has `AmazonSSMManagedInstanceCore` policy
- Check VPC/subnet has route to SSM endpoints (or VPC endpoints configured)

**Command execution failures:**
- Review StandardErrorContent in command invocation results
- Check SSM document syntax and parameters
- Verify instances have required permissions/tools for the commands

---

## Example Workflow with OS Detection

```powershell
# 1. Set variables for int-production
$region = "us-east-1"
$winDocName = "intp-use1-Windows-Banner-Config"
$linuxDocName = "AWS-RunShellScript"
$tagKey = "Environment"
$tagValue = "Shared"

# 2. Find instances by tag
$instanceIds = aws ec2 describe-instances `
  --filters "Name=tag:$tagKey,Values=$tagValue" "Name=instance-state-name,Values=running" `
  --region $region `
  --query "Reservations[*].Instances[*].InstanceId" `
  --output text

Write-Host "Found instances: $instanceIds"

# 3. Check SSM connectivity and get OS type
$instanceInfo = @()
foreach ($id in $instanceIds -split '\s+') {
  $info = aws ssm describe-instance-information `
    --filters "Key=InstanceIds,Values=$id" `
    --region $region `
    --query "InstanceInformationList[0].[InstanceId,PingStatus,PlatformType]" `
    --output json | ConvertFrom-Json
  
  if ($info) {
    $instanceInfo += [PSCustomObject]@{
      InstanceId = $info[0]
      PingStatus = $info[1]
      PlatformType = $info[2]
    }
    Write-Host "$($info[0]) : Status=$($info[1]), OS=$($info[2])"
  }
}

# 4. Separate by OS and execute appropriate documents
$windowsInstances = ($instanceInfo | Where-Object { $_.PlatformType -eq "Windows" -and $_.PingStatus -eq "Online" }).InstanceId
$linuxInstances = ($instanceInfo | Where-Object { $_.PlatformType -eq "Linux" -and $_.PingStatus -eq "Online" }).InstanceId

# Execute Windows document
if ($windowsInstances) {
  Write-Host "`n=== Running Windows Banner Config ==="
  $winCommandId = aws ssm send-command `
    --instance-ids $windowsInstances `
    --document-name $winDocName `
    --region $region `
    --query "Command.CommandId" `
    --output text
  Write-Host "Windows Command ID: $winCommandId"
}

# Execute Linux document
if ($linuxInstances) {
  Write-Host "`n=== Running Linux Configuration ==="
  $linuxCommandId = aws ssm send-command `
    --instance-ids $linuxInstances `
    --document-name $linuxDocName `
    --parameters 'commands=["echo Configuring Linux server"]' `
    --region $region `
    --query "Command.CommandId" `
    --output text
  Write-Host "Linux Command ID: $linuxCommandId"
}

# 5. Wait and get results for Windows

# 5. Wait and get results for Windows
if ($windowsInstances -and $winCommandId) {
  Start-Sleep -Seconds 30
  foreach ($id in $windowsInstances -split '\s+') {
    Write-Host "`n=== Windows Results for $id ==="
    aws ssm get-command-invocation `
      --command-id $winCommandId `
      --instance-id $id `
      --region $region `
      --query '[Status,StandardOutputContent]' `
      --output text
  }
}

# 6. Wait and get results for Linux
if ($linuxInstances -and $linuxCommandId) {
  Start-Sleep -Seconds 30
  foreach ($id in $linuxInstances -split '\s+') {
    Write-Host "`n=== Linux Results for $id ==="
    aws ssm get-command-invocation `
      --command-id $linuxCommandId `
      --instance-id $id `
      --region $region `
      --query '[Status,StandardOutputContent]' `
      --output text
  }
}
```
