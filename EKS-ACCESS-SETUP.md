# EKS Cluster Access Configuration

## Problem Summary
After creating EKS node groups, the Kubernetes system pods existed but were not visible due to IAM authentication issues. Users with AWS SSO Administrator roles could not access the EKS cluster API.

## Solution Applied

### What Was Done
The following AWS CLI commands were executed to grant cluster access to the SSO Administrator role:

```bash
# 1. Update kubeconfig to connect to the cluster
aws eks update-kubeconfig --region us-east-1 --name int-preproduction-use1-shared-eks-cluster-eks-cluster

# 2. Create an access entry for the SSO Administrator role
aws eks create-access-entry \
  --cluster-name int-preproduction-use1-shared-eks-cluster-eks-cluster \
  --principal-arn "arn:aws:iam::730335294148:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_AdministratorAccess_3d0f46907c18b968" \
  --region us-east-1 \
  --type STANDARD

# 3. Associate cluster admin policy to the access entry
aws eks associate-access-policy \
  --cluster-name int-preproduction-use1-shared-eks-cluster-eks-cluster \
  --principal-arn "arn:aws:iam::730335294148:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_AdministratorAccess_3d0f46907c18b968" \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
  --access-scope type=cluster \
  --region us-east-1
```

### Result
- Users can now successfully run `kubectl` commands
- System pods (kube-proxy, CoreDNS, aws-node, etc.) are visible
- Full cluster admin permissions granted

## Making All EKS Clusters Accessible to Identity Center Admin Roles

### Option 1: Using Terraform/Terragrunt (Recommended)

Add the following to your EKS cluster Terraform module to automatically grant access to admin roles:

```hcl
# In your EKS cluster configuration
resource "aws_eks_access_entry" "admin_role" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_AdministratorAccess_3d0f46907c18b968"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "admin_policy" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_eks_access_entry.admin_role.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}
```

### Option 2: Script for Multiple Clusters

Create a script to grant access across all EKS clusters:

```bash
#!/bin/bash
# grant-eks-access.sh

REGION="us-east-1"
ADMIN_ROLE_ARN="arn:aws:iam::730335294148:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_AdministratorAccess_3d0f46907c18b968"
POLICY_ARN="arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

# Get all EKS clusters in the region
CLUSTERS=$(aws eks list-clusters --region $REGION --query 'clusters[]' --output text)

for CLUSTER in $CLUSTERS; do
  echo "Configuring access for cluster: $CLUSTER"
  
  # Create access entry (ignore if already exists)
  aws eks create-access-entry \
    --cluster-name $CLUSTER \
    --principal-arn $ADMIN_ROLE_ARN \
    --region $REGION \
    --type STANDARD 2>/dev/null || echo "Access entry already exists for $CLUSTER"
  
  # Associate admin policy
  aws eks associate-access-policy \
    --cluster-name $CLUSTER \
    --principal-arn $ADMIN_ROLE_ARN \
    --policy-arn $POLICY_ARN \
    --access-scope type=cluster \
    --region $REGION 2>/dev/null || echo "Policy already associated for $CLUSTER"
  
  echo "Completed configuration for $CLUSTER"
  echo "---"
done
```

### Option 3: For Multiple Identity Center Roles

If you have multiple admin roles from Identity Center:

```bash
#!/bin/bash
# grant-multi-role-eks-access.sh

REGION="us-east-1"
ACCOUNT_ID="730335294148"
POLICY_ARN="arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

# List of admin roles (add your role names here)
ADMIN_ROLES=(
  "AWSReservedSSO_AdministratorAccess_3d0f46907c18b968"
  "AWSReservedSSO_PowerUserAccess_xyz123"
  # Add more roles as needed
)

# Get all clusters
CLUSTERS=$(aws eks list-clusters --region $REGION --query 'clusters[]' --output text)

for CLUSTER in $CLUSTERS; do
  echo "Configuring cluster: $CLUSTER"
  
  for ROLE_NAME in "${ADMIN_ROLES[@]}"; do
    ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/aws-reserved/sso.amazonaws.com/${ROLE_NAME}"
    
    echo "  Granting access to role: $ROLE_NAME"
    
    aws eks create-access-entry \
      --cluster-name $CLUSTER \
      --principal-arn $ROLE_ARN \
      --region $REGION \
      --type STANDARD 2>/dev/null
    
    aws eks associate-access-policy \
      --cluster-name $CLUSTER \
      --principal-arn $ROLE_ARN \
      --policy-arn $POLICY_ARN \
      --access-scope type=cluster \
      --region $REGION 2>/dev/null
  done
  
  echo "---"
done
```

## Important Notes

### Authentication Mode
The cluster must be configured with `authenticationMode` set to `API_AND_CONFIG_MAP` or `API` to use access entries. Check with:

```bash
aws eks describe-cluster --name <cluster-name> --region us-east-1 --query 'cluster.accessConfig.authenticationMode'
```

### Finding Your SSO Role ARN
To find your Identity Center role ARN:

```bash
aws sts get-caller-identity
```

The role ARN format for SSO is:
```
arn:aws:iam::<account-id>:role/aws-reserved/sso.amazonaws.com/<role-name>
```

### Available Access Policies
- `AmazonEKSClusterAdminPolicy` - Full cluster admin access
- `AmazonEKSAdminPolicy` - Admin access to specific namespaces
- `AmazonEKSEditPolicy` - Edit resources in namespaces
- `AmazonEKSViewPolicy` - Read-only access

## Verification

After granting access, verify with:

```bash
# Update kubeconfig
aws eks update-kubeconfig --name <cluster-name> --region us-east-1

# Test access
kubectl get nodes
kubectl get pods -A
```

## Troubleshooting

### Error: "couldn't get current server API group list"
- Your IAM role doesn't have access to the cluster
- Run the access entry commands above

### Error: "AccessDeniedException when calling the CreateAccessEntry"
- You don't have permissions to modify the cluster
- Contact your AWS administrator

### Error: "ResourceInUseException: Access entry already exists"
- The access entry is already created
- Skip to associating the policy

## References
- [EKS Access Entries Documentation](https://docs.aws.amazon.com/eks/latest/userguide/access-entries.html)
- [EKS Access Policies](https://docs.aws.amazon.com/eks/latest/userguide/access-policies.html)
