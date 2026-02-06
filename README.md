# AWS Databricks Private Link with Unity Catalog and NCC

This Terraform deployment creates a complete, production-ready AWS Databricks environment with:

- **VPC Endpoints**: Backend (no public IP) deployment for secure networking
- **Unity Catalog**: Fully configured metastore with dedicated S3 bucket
- **External Location**: Separate S3 bucket for external data with Unity Catalog integration
- **Network Connectivity Config (NCC)**: Private endpoint connectivity for all S3 buckets from Databricks account console
- **Dual Deployment**: Optional secondary workspace deployment in a different AWS region for disaster recovery

## Architecture

```
┌─────────────────────────────────────────────────────────────────-┐
│                        AWS Account                               │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │                   Virtual Private Cloud (VPC)              │  │
│  │                                                            │  │
│  │  ┌─────────────┐  ┌──────────────┐  ┌──────────────────┐   │  │
│  │  │   Public    │  │   Private    │  │  VPC Endpoints   │   │  │
│  │  │   Subnet    │  │   Subnet     │  │     Subnet       │   │  │
│  │  │ (Databricks)│  │ (Databricks) │  │  (Endpoints)     │   │  │
│  │  └─────────────┘  └──────────────┘  └──────────────────┘   │  │
│  │                                                            │  │
│  │  ┌──────────────────────────────────────────────────────┐  │  │
│  │  │         Databricks Workspace (Premium)               │  │  │
│  │  │         - No Public IP                               │  │  │
│  │  │         - VPC Endpoints for UI/API                   │  │  │
│  │  │         - Security Groups for access control         │  │  │
│  │  └──────────────────────────────────────────────────────┘  │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │              Unity Catalog Infrastructure                  │  │
│  │                                                            │  │
│  │  ┌──────────────────────┐  ┌────────────────────────────┐  │  │
│  │  │  IAM Role            │  │  Metastore Storage (S3)    │  │  │
│  │  │  (Cross-Account)     │──│  - Versioning Enabled      │  │  │
│  │  │                      │  │  - Encryption at Rest      │  │  │
│  │  └──────────────────────┘  └────────────────────────────┘  │  │
│  │                                                            │  │
│  │  ┌────────────────────────────────────────────────────────┐│  │
│  │  │        External S3 Bucket                              ││  │
│  │  │        - For external tables and data                  ││  │
│  │  │        - Versioning and encryption enabled             ││  │
│  │  └────────────────────────────────────────────────────────┘│  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│              Databricks Account Console (Account-level)          │
│                                                                  | 
│  ┌────────────────────────────────────────────────────────────┐  │
│  │          Network Connectivity Config (NCC)                 │  │
│  │          - Private endpoint rules for:                     │  │
│  │            • Metastore storage                             │  │
│  │            • External location storage                     │  │
│  │          - Workspace binding                               │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │              Unity Catalog Metastore                       │  │
│  │              - Assigned to workspace                       │  │
│  │              - Default catalog                             │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

## Features

### 1. Databricks Workspace (VPC Endpoints)
- Premium SKU workspace with no public IPs
- VPC endpoints for UI/API access
- Custom VPC with dedicated subnets:
  - Public subnet (for control plane communication)
  - Private subnet (for data plane)
  - VPC endpoints subnet (for private endpoints)
- Security Groups with rules for access control

### 2. Unity Catalog
- Dedicated metastore with S3 storage
- IAM role for cross-account authentication
- S3 bucket policies for access control
- Default catalog creation
- Metastore assignment to workspace

### 3. External Location
- Separate S3 bucket for external data
- Unity Catalog external location configured
- Storage credential with IAM role authentication


### 4. Network Connectivity Config (NCC)
- Account-level NCC configuration
- Private endpoint rules for all S3 buckets:
  - Metastore storage
  - External location storage
- NCC binding to workspace
- Secure, private connectivity from Databricks to storage

### 5. Dual Deployment (Optional)
- Secondary workspace deployment in a different AWS region
- Independent Unity Catalog metastore for secondary region
- Cross-region disaster recovery capabilities
- Shared NCC configuration for both workspaces

## Prerequisites

1. **AWS**: Authenticate using AWS Access Keys, copying and pasting in your AWS credentials file
   ```bash
   vi ~/.aws/credentials
   ```  
   Append the key and set the profile names as `primary-account` and `secondary-account`.
   Example
   ```
    [primary-account]
    aws_access_key_id=<INSERT-PRIMARY-ACCOUNT-ACCESS-KEY-ID>
    aws_secret_access_key=<INSERT-PRIMARY-ACCOUNT-SECRET-ACCESS-KEY>
    aws_session_token=<INSERT-PRIMARY-ACCOUNT-SESSION-TOKEN>
    [secondary-account]
    aws_access_key_id=<INSERT-SECONDARY-ACCOUNT-ACCESS-KEY-ID>
    aws_secret_access_key=<INSERT-SECONDARY-ACCOUNT-SECRET-ACCESS-KEY>
    aws_session_token=<INSERT-SECONDARY-ACCOUNT-SESSION-TOKEN>
   ```

2. **Databricks**: Set Service Principal OAuth ID and secret as Terraform Environment Variables
   ```bash
   export TF_VAR_databricks_client_id=<INSERT-OAUTH-SECRET-ID>
   export TF_VAR_databricks_client_secret=<INSERT-OAUTH-SECRET-SECRET>
   ```

3. **Terraform**: Version 1.0+
   ```bash
   terraform version
   ```

4. **Required AWS Permissions**:
   - IAM permissions to create roles, policies, and policies attachments
   - EC2 permissions to create VPCs, subnets, security groups, and VPC endpoints
   - S3 permissions to create buckets, bucket policies, and manage bucket configurations
   - Databricks workspace creation permissions

5. **Databricks Account**:
   - Account console access
   - Account ID (found in the URL at https://accounts.cloud.databricks.com/)

6. **AWS Account Configuration**:
   - Primary AWS account ID
   - Secondary AWS account ID (if deploying secondary workspace)
   - AWS profiles configured for primary and secondary accounts

## Deployment Steps

### 1. Clone and Navigate

```bash
cd aws-dbx-dr-dual-deploy
```

### 2. Configure Variables


Edit `terraform.tfvars` with your values:

```hcl
prefix                      = "myusername"
location                    = "us-east-1"
location_secondary          = "us-west-2"
email                       = "myusername@example.com"
remove_date                 = "2026-12-31"
description                 = "Databricks Private Link with Unity Catalog and NCC"
databricks_account_id       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
aws_primary_account_id      = "123456789012"
aws_secondary_account_id     = "123456789012"
cidr                        = "10.0.0.0/20"
uc_metastore_name           = "my-metastore"
create_external_location    = true
external_location_name      = "external_data"
enable_ncc                  = true
deploy_secondary_workspace  = false
```

### 3. Configure AWS Profiles

Ensure you have AWS profiles configured for primary and secondary accounts:

```bash
# Primary account profile
aws configure --profile primary-account

# Secondary account profile (if deploying secondary workspace)
aws configure --profile secondary-account
```

### 4. Initialize Terraform

```bash
terraform init
```

### 5. Plan Deployment

```bash
terraform plan -var-file=terraform.tfvars
```

If `deploy_secondary_workspace = true`, additional resources will be created in the secondary region.

### 6. Apply Deployment

```bash
terraform apply -var-file=terraform.tfvars
```

Type `yes` when prompted to confirm.

### 7. Verify Deployment

After successful deployment, Terraform will output:

```
workspace_url               = "https://xxxxx.cloud.databricks.com"
workspace_id                = "xxxxx"
workspace_resource_id       = "/subscriptions/.../workspaces/xxxxx"
metastore_id                = "xxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
external_location_name      = "external_data"
ncc_id                      = "xxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

## Usage

### Accessing the Workspace

1. Navigate to the workspace URL from the outputs
2. Since this is a VPC endpoint deployment, ensure you're accessing from an allowed network
3. Log in with your Databricks credentials

### Using Unity Catalog

1. In the Databricks workspace, navigate to **Data** > **Catalogs**
2. You should see the default catalog created by Terraform
3. Create schemas and tables using the metastore storage

### Using the External Location

```sql
-- Create a schema using the external location
CREATE SCHEMA IF NOT EXISTS my_catalog.my_schema
LOCATION 's3://bucket-name/my_schema';

-- Create an external table
CREATE TABLE my_catalog.my_schema.my_table
USING PARQUET
LOCATION 's3://bucket-name/my_table';
```

### Verifying NCC

1. Go to the Databricks Account Console: https://accounts.cloud.databricks.com/
2. Navigate to **Cloud resources** > **Network connectivity configs**
3. You should see the NCC created with:
   - Status: Active
   - Workspace binding
   - Private endpoint rules for both S3 buckets

## Module Structure

```
aws-dbx-dr-dual-deploy/
├── main.tf                           # Root orchestration
├── variables.tf                      # Root variables
├── providers.tf                      # Provider configurations
├── outputs.tf                        # Root outputs
├── terraform.tfvars                  # Configuration file
├── README.md                         # This file
└── modules/
    ├── databricks-workspace/        # Workspace and networking
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   ├── vpc.tf
    │   ├── iam.tf
    │   ├── workspace.tf
    │   └── root-s3.tf
    ├── unity-catalog/               # UC metastore and storage
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── external-location/           # External storage and UC location
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── ncc-storage/                 # NCC configuration
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## Configuration Options

### Optional Features

#### Disable External Location

Set in your tfvars:
```hcl
create_external_location = false
```

#### Disable NCC

Set in your tfvars:
```hcl
enable_ncc = false
```

#### Deploy Secondary Workspace

Enable dual-region deployment:
```hcl
deploy_secondary_workspace = true
location_secondary         = "us-west-2"
aws_secondary_account_id   = "123456789012"
```

## Outputs

| Output | Description |
|--------|-------------|
| `workspace_url` | Databricks workspace URL |
| `workspace_id` | Databricks workspace ID |
| `workspace_resource_id` | Databricks workspace resource ID |
| `metastore_id` | Unity Catalog metastore ID |
| `metastore_name` | Unity Catalog metastore name |
| `metastore_storage_bucket_name` | Metastore S3 bucket name |
| `external_storage_bucket_name` | External S3 bucket name |
| `external_location_name` | Unity Catalog external location name |
| `external_location_url` | External location URL |
| `ncc_id` | Network Connectivity Config ID |
| `ncc_name` | NCC name |
| `ncc_private_endpoint_rules` | Map of private endpoint rules |

## Troubleshooting

### NCC Binding Issues

If NCC binding fails, wait a few minutes and retry:
```bash
terraform apply -var-file=terraform.tfvars -target=module.ncc_storage
```

### Metastore Assignment Errors

Ensure you have account admin permissions in Databricks and verify authentication:
```bash
databricks auth login --host https://accounts.cloud.databricks.com --account-id <account-id>
```

### VPC Endpoint Access Issues

If you can't access the workspace URL:
1. Verify you're on an allowed network
2. Check the Route53 private hosted zone configuration
3. Ensure the VPC endpoint is properly configured
4. Verify security group rules allow your IP address

### S3 Access Issues

If you can't access S3 from Databricks:
1. Verify NCC is properly configured and bound
2. Check IAM role policies on S3 buckets
3. Verify the IAM role has correct permissions
4. Ensure bucket policies allow Databricks access

### Cross-Account Issues

If deploying secondary workspace:
1. Verify AWS profiles are correctly configured
2. Check IAM permissions in both accounts
3. Ensure cross-account access is properly configured

## Cleanup

To destroy all resources:

```bash
terraform destroy -var-file=terraform.tfvars
```

⚠️ **Warning**: This will delete:
- The Databricks workspace(s)
- All S3 buckets and data
- The Unity Catalog metastore(s)
- All networking infrastructure

## Security Considerations

1. **VPC Endpoints**: This deployment uses VPC endpoints for UI/API access. Ensure proper network access controls.

2. **No Public IPs**: The workspace is configured with no public IPs for enhanced security.

3. **IAM Roles**: Storage access uses AWS IAM roles instead of access keys or temporary credentials.

4. **NCC**: Network Connectivity Config ensures storage traffic flows through private endpoints.

5. **RBAC**: Role-based access control is configured for S3 buckets.

6. **Encryption**: S3 buckets use encryption at rest by default. Consider enabling customer-managed keys (KMS) for additional security.

7. **Bucket Policies**: S3 bucket policies restrict access to Databricks services only.

8. **Security Groups**: Network security groups control inbound and outbound traffic.

## Cost Considerations

This deployment creates billable AWS resources:
- Databricks Premium workspace (DBU charges)
- S3 buckets (2x) with versioning enabled
- VPC and subnets
- VPC endpoints
- Route53 private hosted zones
- Data transfer costs

Refer to AWS and Databricks pricing for cost estimates.

## Support

For issues or questions:
1. Check the Databricks documentation: https://docs.databricks.com/
2. Review AWS Databricks best practices: https://docs.databricks.com/en/administration-guide/cloud-configurations/aws/index.html
3. Open an issue in your organization's support channel

## License

This deployment template is provided as-is for internal use.

## References

- [AWS Databricks VPC Endpoints](https://docs.databricks.com/en/administration-guide/cloud-configurations/aws/vpc-endpoints.html)
- [Unity Catalog on AWS](https://docs.databricks.com/en/data-governance/unity-catalog/aws-managed-iam-roles.html)
- [Network Connectivity Config](https://docs.databricks.com/en/security/network/classic/network-connectivity-config.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Databricks Provider](https://registry.terraform.io/providers/databricks/databricks/latest/docs)
