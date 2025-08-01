# Azure Deployment Guide for BCFtools WDL Workflow

This guide explains how to deploy and run the BCFtools WDL workflow on Azure using GitHub Container Registry.

## Prerequisites

1. **Azure Account** with:
   - Azure Batch account
   - Azure Storage account
   - Azure Container Registry (optional, we'll use GitHub Container Registry)

2. **GitHub Account** with:
   - Repository for your workflow
   - GitHub Actions enabled

3. **Tools**:
   - Azure CLI
   - Cromwell with Azure backend support OR Azure WDL runner

## Setup Steps

### 1. Configure GitHub Repository

1. Fork or create a new repository with the workflow files
2. Update the Dockerfile labels with your information:
   ```dockerfile
   LABEL org.opencontainers.image.authors="Your Name"
   LABEL org.opencontainers.image.source="https://github.com/YOUR_USERNAME/YOUR_REPO"
   ```

3. Update the WDL file with your GitHub organization and repository:
   ```wdl
   String github_org = "YOUR_GITHUB_ORG"
   String github_repo = "YOUR_REPO_NAME"
   ```

### 2. Build and Push Container to GitHub Container Registry

1. The GitHub Actions workflow will automatically build and push the container when you:
   - Push to main/master branch
   - Create a release
   - Manually trigger the workflow

2. The container will be available at:
   ```
   ghcr.io/YOUR_GITHUB_ORG/YOUR_REPO_NAME/bcftools-azure:latest
   ```

3. Make the container public (optional):
   - Go to your GitHub profile → Packages
   - Find the bcftools-azure package
   - Settings → Change visibility → Public

### 3. Configure Azure Batch

1. Create an Azure Batch account:
   ```bash
   az batch account create \
     --name YOUR_BATCH_ACCOUNT \
     --resource-group YOUR_RG \
     --location westus2
   ```

2. Create a pool with container support:
   ```bash
   az batch pool create \
     --id bcftools-pool \
     --vm-size Standard_D4s_v3 \
     --target-dedicated-nodes 0 \
     --target-low-priority-nodes 2 \
     --image canonical:0001-com-ubuntu-server-jammy:22_04-lts:latest \
     --container-image-names ghcr.io/YOUR_GITHUB_ORG/YOUR_REPO_NAME/bcftools-azure:latest
   ```

### 4. Configure Azure Storage

1. Create storage containers:
   ```bash
   # For input data
   az storage container create \
     --name data \
     --account-name YOUR_STORAGE_ACCOUNT \
     --auth-mode login

   # For workflow outputs
   az storage container create \
     --name results \
     --account-name YOUR_STORAGE_ACCOUNT \
     --auth-mode login
   ```

2. Upload your VCF files:
   ```bash
   az storage blob upload \
     --container-name data \
     --file your_input.vcf.gz \
     --name input.vcf.gz \
     --account-name YOUR_STORAGE_ACCOUNT

   az storage blob upload \
     --container-name data \
     --file your_input.vcf.gz.tbi \
     --name input.vcf.gz.tbi \
     --account-name YOUR_STORAGE_ACCOUNT
   ```

### 5. Configure Cromwell for Azure

Create `cromwell-azure.conf`:

```hocon
include required(classpath("application"))

backend {
  default = "AzureBatch"
  providers {
    AzureBatch {
      actor-factory = "cromwell.backend.impl.sfs.config.ConfigBackendLifecycleActorFactory"
      config {
        root = "https://YOUR_STORAGE_ACCOUNT.blob.core.windows.net/cromwell-executions"
        
        azure {
          subscription = "YOUR_AZURE_SUBSCRIPTION_ID"
          batch {
            endpoint = "https://YOUR_BATCH_ACCOUNT.YOUR_REGION.batch.azure.com"
            accountName = "YOUR_BATCH_ACCOUNT"
            accountKey = "YOUR_BATCH_ACCOUNT_KEY"
            poolName = "bcftools-pool"
          }
          storage {
            accountName = "YOUR_STORAGE_ACCOUNT"
            accountKey = "YOUR_STORAGE_ACCOUNT_KEY"
          }
        }
        
        filesystems {
          blob {
            class = "cromwell.filesystems.blob.BlobPathBuilderFactory"
            global {
              config {
                subscription = "YOUR_AZURE_SUBSCRIPTION_ID"
                storageAccountName = "YOUR_STORAGE_ACCOUNT"
                storageAccountKey = "YOUR_STORAGE_ACCOUNT_KEY"
                containerName = "cromwell-executions"
              }
            }
          }
        }
        
        default-runtime-attributes {
          docker: "ghcr.io/YOUR_GITHUB_ORG/YOUR_REPO_NAME/bcftools-azure:latest"
          maxRetries: 2
          preemptible: 3
        }
      }
    }
  }
}
```

### 6. Run the Workflow

1. Update `inputs_azure.json` with your values:
   ```json
   {
     "BcftoolsStatsAzure.vcf_file": "https://YOUR_STORAGE_ACCOUNT.blob.core.windows.net/data/input.vcf.gz",
     "BcftoolsStatsAzure.github_org": "YOUR_GITHUB_ORG",
     "BcftoolsStatsAzure.github_repo": "YOUR_REPO_NAME"
   }
   ```

2. Run with Cromwell:
   ```bash
   java -Dconfig.file=cromwell-azure.conf \
     -jar cromwell.jar \
     run bcftools_stats_azure.wdl \
     --inputs inputs_azure.json
   ```

## Using with Azure Genomics (if available)

If using Microsoft Azure Genomics service:

```bash
# Submit workflow
msgen submit \
  --api-url https://YOUR_GENOMICS_ACCOUNT.YOUR_REGION.genomics.azure.net \
  --access-key YOUR_ACCESS_KEY \
  --workflow-path bcftools_stats_azure.wdl \
  --inputs-file inputs_azure.json \
  --outputs-container-name results
```

## Monitoring and Outputs

1. Monitor job progress:
   ```bash
   # Check Batch job status
   az batch job list --account-name YOUR_BATCH_ACCOUNT

   # Check task status
   az batch task list --job-id YOUR_JOB_ID --account-name YOUR_BATCH_ACCOUNT
   ```

2. Download results:
   ```bash
   # List output files
   az storage blob list \
     --container-name results \
     --account-name YOUR_STORAGE_ACCOUNT

   # Download results
   az storage blob download \
     --container-name results \
     --name azure_vcf_stats.stats.txt \
     --file local_stats.txt \
     --account-name YOUR_STORAGE_ACCOUNT
   ```

## Cost Optimization

1. **Use Low Priority VMs**: Configured in the pool creation with `--target-low-priority-nodes`
2. **Auto-scaling**: Configure pool auto-scaling based on pending tasks
3. **Preemptible Instances**: The workflow is configured to handle preemption
4. **Clean up resources**: Delete pools when not in use

## Troubleshooting

### Container Access Issues
- Ensure GitHub Container Registry is public or configure authentication
- Check Azure Batch pool has access to pull containers

### Storage Access Issues
- Verify storage account keys and permissions
- Check firewall rules allow Batch pool access

### Task Failures
- Check task stderr/stdout in Azure Portal
- Review Cromwell logs for detailed error messages
- Verify input file paths are accessible

## Security Best Practices

1. Use Managed Identities instead of storage keys when possible
2. Store sensitive credentials in Azure Key Vault
3. Use private endpoints for storage accounts
4. Enable encryption at rest for all storage
5. Regularly rotate access keys

## Advanced Configuration

### Using Private GitHub Container Registry

If your container is private, configure authentication:

1. Create a GitHub Personal Access Token with `read:packages` scope
2. Store in Azure Key Vault
3. Configure Batch pool with registry credentials

### Multi-region Deployment

For better performance, deploy resources in the same region:
- Batch account
- Storage account
- Container registry (if using ACR)

### Scaling for Large Datasets

For processing many VCF files:
1. Use scatter-gather pattern in WDL
2. Configure larger Batch pools
3. Use premium storage for better I/O
